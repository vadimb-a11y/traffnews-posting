# Telegram Bot API — Integration Spec

## Что нужно

- **Bot Token** формата `123456789:ABCdef...` — создаётся через `@BotFather`, `/newbot`
- **Channel ID** — `@traffnews` (для публичных каналов) или `-100xxxxxxxxxx` (для приватных)
- Бот должен быть **админом канала** с правом **Post Messages**

После создания бота:
- `/setjoingroups @your_bot_name` → **Disable** (не давать боту вступать в группы случайно)
- `/setprivacy @your_bot_name` → **Enable** (privacy mode, бот не видит сообщения групп)

## Base URL

```
https://api.telegram.org/bot{TOKEN}/{method}
```

Все запросы — POST с body `application/json`. Token расшифровывается per-request из `social_secrets.encrypted_token`.

## Методы

Используем 3 endpoint, в зависимости от количества медиа в посте:

| Кол-во картинок | Метод |
|---|---|
| 0 | `sendMessage` |
| 1 | `sendPhoto` |
| 2-10 | `sendMediaGroup` |

### `sendMessage` — текст без медиа

```http
POST https://api.telegram.org/bot{TOKEN}/sendMessage
Content-Type: application/json

{
  "chat_id": "@traffnews",
  "text": "<b>💸 Думаешь о пассивном доходе?</b>\n\nСкорее всего...\n\n<a href=\"https://traffnews.com/...\">Читай на TRAFFNEWS 👉</a>\n\n#полезное",
  "parse_mode": "HTML",
  "disable_web_page_preview": false
}
```

**Лимит:** text ≤ 4096 chars.

### `sendPhoto` — одна картинка

```http
POST https://api.telegram.org/bot{TOKEN}/sendPhoto
Content-Type: application/json

{
  "chat_id": "@traffnews",
  "photo": "https://your-supabase-storage/social-media/{post_id}/img1.jpg",
  "caption": "<b>💸 Думаешь...</b>\n\n#полезное",
  "parse_mode": "HTML"
}
```

**Лимит:** caption ≤ 1024 chars (важно — меньше чем `sendMessage` text!). Размер картинки ≤ 10 MB, ratio до 20:1.

URL картинки должен быть публично доступен. Storage bucket `social-media` настроен на public read — подойдёт.

### `sendMediaGroup` — карусель 2-10 картинок

```http
POST https://api.telegram.org/bot{TOKEN}/sendMediaGroup
Content-Type: application/json

{
  "chat_id": "@traffnews",
  "media": [
    {
      "type": "photo",
      "media": "https://.../img1.jpg",
      "caption": "<b>💸 Думаешь...</b>\n\n#полезное",
      "parse_mode": "HTML"
    },
    { "type": "photo", "media": "https://.../img2.jpg" },
    { "type": "photo", "media": "https://.../img3.jpg" },
    ...
  ]
}
```

**Важно:** caption кладётся только в **первый** элемент массива. Остальные — без caption. TG показывает caption под всей группой.

**Лимит:** массив `media` 2-10 элементов. Caption ≤ 1024 chars.

## Format options для caption

Используем `parse_mode: "HTML"` (проще чем MarkdownV2 для генерации).

Поддерживаемые теги:
- `<b>bold</b>`, `<i>italic</i>`, `<u>underline</u>`, `<s>strikethrough</s>`
- `<a href="url">link</a>` — кликабельные ссылки
- `<code>monospace</code>`, `<pre>block</pre>`
- `<blockquote>quote</blockquote>`
- `<spoiler>hidden</spoiler>`

**Запрещено:** другие HTML-теги типа `<div>`, `<p>`, `<br>`. Переносы строк — `\n`.

**Escaping:** символы `<`, `>`, `&` внутри текста (не в тегах) — экранировать как `&lt;`, `&gt;`, `&amp;`.

Используем `isomorphic-dompurify` с allowlist `['b','i','u','s','a','code','pre','blockquote','spoiler']` и `href` атрибутом только для `<a>`.

## Response

Успех:
```json
{
  "ok": true,
  "result": {
    "message_id": 12345,
    "chat": { "id": -1001234567890, ... },
    "date": 1715456789,
    ...
  }
}
```

Сохраняем `result.message_id` → `social_posts.tg_message_id`.

URL опубликованного сообщения для UI: `https://t.me/c/{chat_id без -100 префикса}/{message_id}` (приватный) или `https://t.me/{channel_username}/{message_id}` (публичный).

Ошибка:
```json
{
  "ok": false,
  "error_code": 400,
  "description": "Bad Request: chat not found"
}
```

## Обработка ошибок

| `error_code` | Описание | Действие |
|---|---|---|
| 400 + `chat not found` | Канал не существует / бот не добавлен | UI: alert "Проверьте что бот добавлен админом в канал" |
| 401 + `Unauthorized` | Токен невалидный / отозван | UI: alert "Обновите Bot Token в Settings" |
| 403 + `bot was blocked` | Канал заблокировал бота (редко для каналов) | UI: alert "Бот заблокирован в канале, переподключите" |
| 429 + `Too Many Requests` | Rate limit | Backend: retry с exponential backoff (jitter), max 3 попытки |
| 500 / 502 / 503 | TG temporary issue | Backend: retry 3 раза с задержкой, потом fail |

При 429 в ответе будет `parameters.retry_after` (секунды) — ждать столько и retry.

## Rate limits TG Bot API

- **Группа/канал:** не более 20 сообщений в минуту в один и тот же канал
- **Глобально для бота:** не более 30 сообщений в секунду на все каналы

Для нашего use case (несколько постов в день) — некритично, но cron-publisher должен это учитывать если будут массовые scheduled.

## Test connection

`POST /api/social/secrets/telegram/test`:

```pseudo
token = decrypt(social_secrets.encrypted_token where platform='telegram')
GET https://api.telegram.org/bot{token}/getMe

if response.ok:
  return { ok: true, bot_username: response.result.username }
else:
  return { ok: false, error: response.description }
```

Дополнительно — `getChat` на канал чтобы убедиться что бот его видит:

```
GET https://api.telegram.org/bot{token}/getChat?chat_id=@traffnews
```

Если 400 — бот не в канале или username неверный.

## Pseudo-implementation

```typescript
// /lib/social/telegram.ts

import sanitizeHtml from 'isomorphic-dompurify';

const ALLOWED_TAGS = ['b','i','u','s','a','code','pre','blockquote','spoiler'];

async function sendToTelegram(post: SocialPost, token: string, channelId: string) {
  const safeCaption = sanitizeHtml(post.tg_caption, {
    allowedTags: ALLOWED_TAGS,
    allowedAttributes: { a: ['href'] },
  });

  const captionWithHashtag = post.tg_hashtag
    ? `${safeCaption}\n\n${post.tg_hashtag}`
    : safeCaption;

  const media = post.media_urls;

  let result;
  if (media.length === 0) {
    result = await tgApi('sendMessage', token, {
      chat_id: channelId,
      text: captionWithHashtag,
      parse_mode: 'HTML',
      disable_web_page_preview: false,
    });
  } else if (media.length === 1) {
    result = await tgApi('sendPhoto', token, {
      chat_id: channelId,
      photo: media[0],
      caption: captionWithHashtag,
      parse_mode: 'HTML',
    });
  } else {
    const mediaArray = media.map((url, idx) =>
      idx === 0
        ? { type: 'photo', media: url, caption: captionWithHashtag, parse_mode: 'HTML' }
        : { type: 'photo', media: url }
    );
    result = await tgApi('sendMediaGroup', token, {
      chat_id: channelId,
      media: mediaArray,
    });
  }

  // sendMediaGroup возвращает массив, остальные — один объект
  const firstMessage = Array.isArray(result) ? result[0] : result;
  return { message_id: firstMessage.message_id };
}

async function tgApi(method: string, token: string, body: any) {
  const res = await fetch(`https://api.telegram.org/bot${token}/${method}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  if (!data.ok) {
    throw new Error(`telegram_${method}_failed: ${data.description}`);
  }
  return data.result;
}
```
