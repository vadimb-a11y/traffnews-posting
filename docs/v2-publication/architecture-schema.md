# Architecture & Schema

## Supabase tables

Все таблицы создаются в существующем Supabase проекте CS Dashboard. Префикс `social_` чтобы не конфликтовать с другими модулями (`wordpress_*`, `sites_*` уже есть).

### `social_posts`

Один пост (TG + IG версии под одной шапкой).

```sql
create table social_posts (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,                -- внутреннее имя для SMM (не публикуется)
  source_url      text,                          -- если пост создан из RSS-статьи: ссылка на оригинал
  source_rss_item_id uuid references social_rss_items(id) on delete set null,

  tg_caption      text,                          -- HTML-форматированный текст для Telegram
  tg_hashtag      text,                          -- один навигационный хэштег (#полезное / #новости / ...)

  ig_caption      text,                          -- plain-текст для Instagram (без HTML)
  ig_hashtags     text,                          -- "#тег1 #тег2 ..." строкой (10-30 тегов)

  media_urls      jsonb not null default '[]'::jsonb,  -- array of Supabase Storage public URLs

  publish_to_tg   boolean not null default true,
  publish_to_ig   boolean not null default false,  -- IG требует хотя бы 1 медиа

  status          text not null default 'draft',
                  -- draft | scheduled | publishing | posted | failed
  publish_at      timestamptz,                   -- null = публиковать сейчас при triggers
  published_at    timestamptz,

  tg_message_id   bigint,                        -- результат публикации TG
  ig_media_id     text,                          -- результат публикации IG
  error_message   text,                          -- если status=failed

  created_at      timestamptz not null default now(),
  created_by      uuid references auth.users(id) on delete set null,
  updated_at      timestamptz not null default now()
);

create index idx_social_posts_status on social_posts(status);
create index idx_social_posts_publish_at on social_posts(publish_at) where status = 'scheduled';
create index idx_social_posts_created_by on social_posts(created_by);

-- updated_at trigger
create trigger trg_social_posts_updated_at
  before update on social_posts
  for each row execute function moddatetime(updated_at);
```

### `social_secrets`

Зашифрованные tokens для TG/IG. Один ряд на платформу. Шифрование AES-256-GCM, см. `docs/hard-rules.md`.

```sql
create table social_secrets (
  id                  uuid primary key default gen_random_uuid(),
  platform            text not null unique,       -- 'telegram' | 'instagram'
  encrypted_token     text not null,              -- base64(iv ‖ ciphertext ‖ authTag)
  metadata            jsonb not null default '{}'::jsonb,
                      -- TG: { bot_username, channel_id }
                      -- IG: { business_account_id, page_id, app_id, expires_at }
  expires_at          timestamptz,                -- для IG (60 дней)
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

create index idx_social_secrets_expires_at on social_secrets(expires_at);
```

### `social_rss_sources`

Подписки RSS для Radar tab. SMM может добавлять/убирать через UI.

```sql
create table social_rss_sources (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,                     -- "Traffnews", "AdIndex", ...
  url         text not null unique,              -- https://traffnews.com/feed/
  is_own      boolean not null default false,    -- true = наш сайт, false = конкурент
  is_active   boolean not null default true,
  last_polled_at timestamptz,
  created_at  timestamptz not null default now()
);

-- Seed
insert into social_rss_sources (name, url, is_own) values
  ('Traffnews', 'https://traffnews.com/feed/', true);
```

### `social_rss_items`

Кэш статей из RSS. Cron job-puller заполняет, UI читает.

```sql
create table social_rss_items (
  id              uuid primary key default gen_random_uuid(),
  source_id       uuid not null references social_rss_sources(id) on delete cascade,
  guid            text not null,                  -- уникальный ID статьи внутри source (link или guid из RSS)
  title           text not null,
  link            text not null,
  description     text,
  content_html    text,
  cover_image_url text,                            -- первая <img> из content_html
  author          text,
  published_at    timestamptz,
  is_read         boolean not null default false,  -- SMM пометил "видел"
  is_used         boolean not null default false,  -- из этого item уже создан пост
  fetched_at      timestamptz not null default now(),
  unique(source_id, guid)
);

create index idx_social_rss_items_published_at on social_rss_items(published_at desc);
create index idx_social_rss_items_source_unread on social_rss_items(source_id, is_read) where is_read = false;
```

## API routes

Все routes Next.js под `/app/api/social/`. Auth — Supabase session (тот же что и у Dashboard). Все routes server-side; БД через Supabase service-role (никаких client→DB прямых запросов).

### Posts CRUD

| Method | Path | Назначение |
|---|---|---|
| `GET` | `/api/social/posts?status=draft` | Список постов с фильтром по статусу |
| `GET` | `/api/social/posts/[id]` | Один пост |
| `POST` | `/api/social/posts` | Создать черновик (опционально с `source_rss_item_id`) |
| `PATCH` | `/api/social/posts/[id]` | Обновить поля (caption, media, publish_at, ...) |
| `DELETE` | `/api/social/posts/[id]` | Удалить (только draft / scheduled) |
| `POST` | `/api/social/posts/[id]/publish` | Опубликовать сейчас (синхронно) |
| `POST` | `/api/social/posts/[id]/schedule` | Поставить в очередь (status=scheduled, publish_at в будущем) |
| `POST` | `/api/social/posts/[id]/cancel-schedule` | Откатить scheduled → draft |

#### `POST /api/social/posts/[id]/publish`

**Request:** body не обязателен (всё уже в БД).

**Response (200):**
```json
{
  "ok": true,
  "tg_message_id": 1234,
  "ig_media_id": "17841408449121234",
  "published_at": "2026-05-11T18:00:00Z"
}
```

**Response (4xx/5xx):**
```json
{
  "ok": false,
  "error": "tg_send_failed: chat not found",
  "partial": { "tg_message_id": 1234 }
}
```

Если одна платформа упала, а вторая прошла — статус = `failed`, `error_message` заполнен, `partial` содержит то что прошло. В БД фиксируем что прошло.

### RSS

| Method | Path | Назначение |
|---|---|---|
| `GET` | `/api/social/rss-sources` | Список источников |
| `POST` | `/api/social/rss-sources` | Добавить источник `{ name, url, is_own }` |
| `DELETE` | `/api/social/rss-sources/[id]` | Удалить источник |
| `GET` | `/api/social/rss-items?is_read=false&limit=50` | Лента для Radar tab |
| `PATCH` | `/api/social/rss-items/[id]` | Пометить `is_read` / `is_used` |
| `POST` | `/api/social/rss-items/[id]/create-post` | Создать draft `social_posts` из item, вернуть `post_id` |

### Secrets (admin only)

| Method | Path | Назначение |
|---|---|---|
| `GET` | `/api/social/secrets` | Список секретов **без раскрытия токенов** (только platform + metadata + expires_at) |
| `POST` | `/api/social/secrets` | Создать/обновить токен платформы. Токен в plaintext в request body (HTTPS!), сразу шифруется и кладётся в БД |
| `POST` | `/api/social/secrets/[platform]/refresh` | Принудительный refresh IG token |
| `DELETE` | `/api/social/secrets/[platform]` | Удалить (отключить платформу) |

Доступ только для admin role (проверка `auth.users` → admin claim).

## Cron jobs

3 cron-задачи. Запуск — Vercel Cron / Supabase Edge Functions Scheduled / отдельный systemd-timer на VPS. Все идемпотентны.

### `cron_rss_poll` — каждые 30 минут

```
for source in social_rss_sources where is_active = true:
  fetch RSS, parse items
  for item in items:
    if not exists social_rss_items(source_id, guid):
      extract cover_image_url from content_html (first <img>)
      insert social_rss_items
  update source.last_polled_at = now()
```

### `cron_publish_scheduled` — каждую минуту

```
for post in social_posts where status='scheduled' and publish_at <= now() limit 10:
  set post.status = 'publishing'  -- lock
  call publish(post)              -- same handler as /publish endpoint
```

Lock на `publishing` чтобы избежать гонок если cron запустится дважды.

### `cron_refresh_ig_token` — раз в сутки

```
for secret in social_secrets where platform='instagram' and expires_at < now() + interval '7 days':
  decrypt(secret.encrypted_token) → access_token
  GET https://graph.facebook.com/v21.0/oauth/access_token
    ?grant_type=fb_exchange_token
    &client_id={FB_APP_ID}
    &client_secret={FB_APP_SECRET}
    &fb_exchange_token={access_token}
  → new long-lived token (60 days)
  encrypt + update secret.encrypted_token + secret.expires_at
  log success
on failure: alert in TELEGRAM_ADMIN_CHAT_ID
```

## Supabase Storage

Bucket `social-media`:
- Public read (для подачи Instagram Graph API — IG требует публичные URL картинок)
- Authenticated write (только из dashboard)
- Path-pattern: `social-media/{post_id}/{filename}`

При удалении поста — удалять и связанные файлы из Storage.

## Multi-platform send logic

Когда триггерится publish:

```pseudo
function publish(post):
  results = { tg: null, ig: null, errors: [] }

  if post.publish_to_tg and TG_TOKEN_AVAILABLE:
    try:
      results.tg = sendToTelegram(post)
    except e:
      results.errors.push({ platform: 'tg', error: e.message })

  if post.publish_to_ig and IG_TOKEN_AVAILABLE and len(post.media_urls) > 0:
    try:
      results.ig = sendToInstagram(post)
    except e:
      results.errors.push({ platform: 'ig', error: e.message })

  if results.errors:
    post.status = 'failed'
    post.error_message = JSON.stringify(results.errors)
  else:
    post.status = 'posted'

  post.tg_message_id = results.tg?.message_id
  post.ig_media_id = results.ig?.media_id
  post.published_at = now()
  save(post)
  return results
```

См. подробности platform-specific вызовов:
- `docs/spec-telegram.md`
- `docs/spec-instagram.md`
