# Hard Rules

Правила, нарушение которых ломает либо безопасность, либо постинг. Должны проверяться **до** «ready to publish».

## 1. Plaintext credentials не покидают серверный процесс

- TG Bot Token, IG Access Token, IG App Secret хранятся в Supabase **только зашифрованными** (AES-256-GCM)
- Расшифровка — **per-request**, для одного запроса публикации; в памяти не держим, после ответа — мусорится
- Если credential логируется (в `console.log` / Sentry / Supabase logs) — это инцидент. Логи проверять regex'ом на `EAA*`, `bot[0-9]+:`
- Plaintext **никогда** не возвращается через API даже админу. Settings UI показывает только `[●●●●●●●●●● (hidden)]` + metadata (bot_username, expires_at)

### Encryption pattern (повторяем как в WPCNT-02)

```typescript
// /lib/crypto.ts
import { createCipheriv, createDecipheriv, randomBytes } from 'node:crypto';

const KEY = Buffer.from(process.env.ENCRYPTION_KEY!, 'hex'); // 32 bytes
const ALGO = 'aes-256-gcm';

export function encrypt(plaintext: string): string {
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGO, KEY, iv);
  const enc = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const tag = cipher.getAuthTag();
  return Buffer.concat([iv, enc, tag]).toString('base64'); // iv ‖ ciphertext ‖ tag
}

export function decrypt(b64: string): string {
  const buf = Buffer.from(b64, 'base64');
  const iv = buf.subarray(0, 12);
  const tag = buf.subarray(buf.length - 16);
  const ct = buf.subarray(12, buf.length - 16);
  const decipher = createDecipheriv(ALGO, KEY, iv);
  decipher.setAuthTag(tag);
  return Buffer.concat([decipher.update(ct), decipher.final()]).toString('utf8');
}
```

`ENCRYPTION_KEY` — 64 hex chars (32 bytes), общий с Dashboard (тот же что у WPCNT-02 для Application Passwords).

## 2. Нет прямых API ключей anthropic / openai

- В CS Dashboard env переменных `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` **нет и не должно быть**
- Если в v3+ понадобится AI (кнопка "rewrite caption") — звонить через OpenClaw Gateway:
  ```
  POST {OPENCLAW_GATEWAY_URL}/v1/chat/completions
  Authorization: Bearer {OPENCLAW_AUTH_TOKEN}
  ```
- Модели: `anthropic/claude-haiku-4-5` (default), `anthropic/claude-sonnet-4-6`, `openai-codex/gpt-5.4`
- Cost = subscription extra usage, не API billing

## 3. HTML sanitization

Любой caption, который идёт во внешний API (TG / IG) — обязательно через `isomorphic-dompurify`.

### Для TG

```typescript
import sanitizeHtml from 'isomorphic-dompurify';

const TG_ALLOWED_TAGS = ['b','i','u','s','a','code','pre','blockquote','spoiler'];

const safe = sanitizeHtml(rawCaption, {
  ALLOWED_TAGS: TG_ALLOWED_TAGS,
  ALLOWED_ATTR: ['href'],
});
```

Если SMM вставит `<script>`, `<img onerror=...>` или unclosed `<` — sanitize вычистит. Без этого TG вернёт `Bad Request: can't parse entities`.

### Для IG

IG caption — plain text + emoji + хэштеги. **Никакого HTML.** Strip всё:

```typescript
const safeIg = sanitizeHtml(rawCaption, { ALLOWED_TAGS: [], ALLOWED_ATTR: [] });
```

## 4. Лимиты — UI должен enforce ДО Publish

| Платформа | Параметр | Лимит | Что показывать в UI |
|---|---|---|---|
| TG | `sendMessage` text | 4096 chars | counter `N / 4096` |
| TG | `sendPhoto` / `sendMediaGroup` caption | **1024 chars** | counter `N / 1024` (важно: если есть media — лимит ниже!) |
| TG | media group items | 2-10 | счётчик `N / 10` |
| IG | caption | 2200 chars | counter |
| IG | hashtags | 30 max | счётчик хэштегов |
| IG | media | 1-10 (REQUIRED ≥1) | block Publish если 0 |
| IG | image | JPEG only, ≤8MB, ratio 4:5..1.91:1 | конвертация + ресайз при upload |

Backend дублирует проверки — UI можно обойти через прямой API call. Reject с 400 если нарушено.

## 5. IG Token expiry monitoring

- IG long-lived token живёт **60 дней**
- Cron `cron_refresh_ig_token` раз в сутки рефрешит если `expires_at < now() + 7 days`
- Если refresh упал (5xx, token уже мёртв, permissions revoked) — **alert в `TELEGRAM_ADMIN_CHAT_ID`**, плюс в Settings UI красный бейдж
- В `/api/social/posts/[id]/publish` перед IG-вызовом — проверка `expires_at > now()`. Если нет — early reject с понятной ошибкой.

## 6. Tool calling — через `/api/openclaw/tools`

Если в будущем появится агент SOCIAL-04 в OpenClaw — он **не пишет в Supabase напрямую**. Только через dashboard tool proxy:

```
POST {DASHBOARD}/api/openclaw/tools
Authorization: Bearer {DASHBOARD_TOOL_TOKEN}
Content-Type: application/json

{ "tool": "social.create_draft", "args": { ... } }
```

Tool whitelist (минимальный набор для агента):
- `social.list_rss_items`
- `social.create_draft`
- `social.read_draft`
- (НЕ `social.publish` — публикация только из UI триггера SMM)

## 7. Pre-publish checklist (server-side, в `/publish` route)

Перед каждым вызовом TG/IG API проверить:

```pseudo
function preflightCheck(post):
  if post.status not in ['draft', 'scheduled', 'publishing']:
    fail('invalid_status: cannot publish already-posted/failed post')

  if not post.publish_to_tg and not post.publish_to_ig:
    fail('no_platform: at least one platform required')

  if post.publish_to_ig and len(post.media_urls) == 0:
    fail('ig_requires_media')

  if post.publish_to_ig:
    secret = social_secrets where platform='instagram'
    if not secret or secret.expires_at < now():
      fail('ig_token_expired_or_missing')

  if post.publish_to_tg:
    secret = social_secrets where platform='telegram'
    if not secret:
      fail('tg_token_missing')

  # Sanitize captions
  safeTg = sanitize_for_tg(post.tg_caption)
  safeIg = sanitize_for_ig(post.ig_caption)

  # Length checks (после sanitize, т.к. может стать короче)
  if post.publish_to_tg:
    maxTgLen = 1024 if media.length > 0 else 4096
    if len(safeTg + post.tg_hashtag) > maxTgLen:
      fail(f'tg_caption_too_long: {len} > {maxTgLen}')

  if post.publish_to_ig:
    if len(safeIg + post.ig_hashtags) > 2200:
      fail('ig_caption_too_long')
    if count_hashtags(post.ig_hashtags) > 30:
      fail('ig_too_many_hashtags')

  # Media checks
  if len(post.media_urls) > 10:
    fail('too_many_media: max 10')

  for url in post.media_urls:
    if not is_public_https(url):
      fail(f'media_not_public: {url}')
```

Если что-то fail — `post.status = 'failed'`, `error_message` заполнен, response 4xx.

## 8. Rate limit на API routes

Запретить публиковать чаще раз в 5 секунд (от случайного двойного клика):

```typescript
// /api/social/posts/[id]/publish
const rateLimited = await checkRateLimit(`publish:${userId}`, { window: 5, max: 1 });
if (rateLimited) return 429;
```

Использовать существующий rate-limit механизм Dashboard (тот же что для `/api/openclaw/tools`).

## 9. Audit log

Каждый `publish` пишет в существующую Dashboard audit-таблицу (или в `Sessions / Logs` Notion DB):

```
event: social.publish
actor: {user_email}
post_id: {uuid}
platforms: ['tg','ig']
result: ok | partial | failed
ts: {timestamp}
```

Для compliance + debugging "кто и когда опубликовал что".

## 10. Удаление поста = soft delete

`DELETE /api/social/posts/[id]` ставит `status = 'deleted'`, не делает физический `DELETE FROM`. Reasoning: если SMM случайно удалил — можно восстановить. Cron подчищает старше 30 дней.

Если `status = 'posted'` — `DELETE` запрещён через UI. Удалить пост в TG/IG **не пытаемся** автоматически (для TG это `deleteMessage`, для IG — `DELETE /{media_id}` — но опасно, лучше делать руками в админке платформ).
