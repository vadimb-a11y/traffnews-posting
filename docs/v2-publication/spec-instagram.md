# Instagram Graph API — Integration Spec

Из всех платформ — самая болезненная. Требует Facebook Developer App + Business аккаунт + долгую цепочку получения tokens. Один раз настроили — потом просто refresh.

## Что нужно

- **Instagram Business Account** (не Personal!), привязанный к **Facebook Page**
- **Facebook App** в developers.facebook.com с продуктами:
  - Instagram Graph API
  - Facebook Login (для OAuth flow)
- Permissions для App:
  - `instagram_basic`
  - `instagram_content_publish`
  - `pages_show_list`
  - `pages_read_engagement`
- **Long-lived Access Token** (60 дней) — получается через OAuth flow + exchange
- **Instagram Business Account ID** — числовой
- **Facebook Page ID** — числовой

## Получение начального токена (manual setup, один раз)

Описано в Meta docs: https://developers.facebook.com/docs/instagram-platform/instagram-graph-api/getting-started

Кратко:
1. В Facebook App settings → Add Product → Instagram Graph API
2. Через Graph API Explorer получить short-lived User Access Token с нужными permissions
3. Exchange на long-lived (60 дней):
   ```
   GET https://graph.facebook.com/v21.0/oauth/access_token
     ?grant_type=fb_exchange_token
     &client_id={FB_APP_ID}
     &client_secret={FB_APP_SECRET}
     &fb_exchange_token={short_lived_token}
   ```
4. Получить Page Access Token:
   ```
   GET https://graph.facebook.com/v21.0/me/accounts
     ?access_token={long_lived_user_token}
   ```
   В ответе для каждой страницы есть `access_token` — это и есть нужный нам Page Access Token (он тоже long-lived).
5. Получить Instagram Business Account ID:
   ```
   GET https://graph.facebook.com/v21.0/{page_id}?fields=instagram_business_account&access_token={page_token}
   ```

Полученные `INSTAGRAM_ACCESS_TOKEN` (= page access token), `INSTAGRAM_BUSINESS_ACCOUNT_ID`, `FACEBOOK_PAGE_ID` положить в Settings tab Dashboard → шифруются и сохраняются в `social_secrets`.

## Base URL

```
https://graph.facebook.com/v21.0/{ig-user-id}
```

`{ig-user-id}` = Instagram Business Account ID.

## Публикация — 2-step

В отличие от Telegram, IG требует **2 шага**:
1. **Create media container** — Meta готовит контейнер на своей стороне (загружает картинку с публичного URL)
2. **Publish container** — публикуем готовый контейнер в ленту

### Single image post

#### Step 1: Create container

```http
POST https://graph.facebook.com/v21.0/{ig-user-id}/media
Content-Type: application/x-www-form-urlencoded

image_url=https%3A%2F%2Fyour-supabase%2F.../img1.jpg
&caption=Сегодня%20поговорим%20про...%0A%0A%23арбитраж%20%23cpa
&access_token={token}
```

**Response:**
```json
{ "id": "17889455560313623" }  // container_id
```

#### Step 2: Publish

```http
POST https://graph.facebook.com/v21.0/{ig-user-id}/media_publish
Content-Type: application/x-www-form-urlencoded

creation_id=17889455560313623
&access_token={token}
```

**Response:**
```json
{ "id": "17888500256064231" }  // ig_media_id — финальный ID опубликованного поста
```

Сохраняем `id` → `social_posts.ig_media_id`. URL поста: `https://www.instagram.com/p/{shortcode}/`, где `shortcode` извлекается отдельным запросом (опционально).

### Carousel (2-10 images)

Сложнее — каждая картинка = свой child container, потом ещё один parent carousel container.

#### Step 1a: Create child containers (для каждой картинки)

Для каждого `media_url`:
```http
POST https://graph.facebook.com/v21.0/{ig-user-id}/media
image_url={url}
&is_carousel_item=true
&access_token={token}
```

Получаем массив `child_ids = [container_id_1, container_id_2, ...]`.

#### Step 1b: Create carousel parent container

```http
POST https://graph.facebook.com/v21.0/{ig-user-id}/media
media_type=CAROUSEL
&children={child_id_1},{child_id_2},...
&caption={encoded_caption}
&access_token={token}
```

Response: `{ "id": "carousel_container_id" }`.

#### Step 2: Publish parent

```http
POST https://graph.facebook.com/v21.0/{ig-user-id}/media_publish
creation_id={carousel_container_id}
&access_token={token}
```

Response: `{ "id": ig_media_id }`.

## Ограничения IG

| Параметр | Лимит |
|---|---|
| Caption length | 2200 chars |
| Hashtags | 30 max в caption (Meta считает строго) |
| Carousel children | 2-10 |
| Image format | JPEG (PNG → конвертить перед upload в Storage) |
| Image max size | 8 MB |
| Image min ratio | 4:5 (portrait) до 1.91:1 (landscape) |
| Image URL | Must be **public HTTPS** (Supabase Storage public read — OK) |
| Posts per day | 25 на аккаунт (Graph API лимит, не Insta UI) |

## Token expiry

Long-lived Page Access Token живёт 60 дней. Refresh:

```http
GET https://graph.facebook.com/v21.0/oauth/access_token
  ?grant_type=fb_exchange_token
  &client_id={FB_APP_ID}
  &client_secret={FB_APP_SECRET}
  &fb_exchange_token={current_token}
```

Response:
```json
{
  "access_token": "EAA...",
  "token_type": "bearer",
  "expires_in": 5183944
}
```

Получаем новый, шифруем, заменяем в `social_secrets.encrypted_token`, обновляем `expires_at = now() + expires_in`.

Cron `cron_refresh_ig_token` запускается раз в сутки, рефрешит если `expires_at < now() + 7 days`.

Если refresh упал (5xx от Meta, токен уже протух 60+ дней, или App permissions отозваны) — alert в `TELEGRAM_ADMIN_CHAT_ID` + UI в Settings показывает красный бейдж "Token expired, re-authorize".

## Response polling

Иногда IG не публикует мгновенно — container в статусе `IN_PROGRESS`. Можно проверить:

```http
GET https://graph.facebook.com/v21.0/{container_id}?fields=status_code&access_token={token}
```

Status codes: `EXPIRED`, `ERROR`, `FINISHED`, `IN_PROGRESS`, `PUBLISHED`.

В пайплайне: после Step 1 (create container) ждём 2-3 секунды и сразу делаем `media_publish`. Если падает с ошибкой "container not ready" — retry с задержкой. Для UI: показывать "Publishing..." до 30 сек.

## Обработка ошибок

| `error.code` | Описание | Действие |
|---|---|---|
| `190` | Invalid OAuth token | Token протух — UI alert, попросить refresh/re-auth |
| `200` | Permission denied | App permissions отозваны или IG аккаунт переключён в Personal |
| `100` + `image_url is not accessible` | Картинка недоступна публично | Проверить Storage bucket policy |
| `100` + `media type not supported` | Не JPEG / неверный ratio / >8MB | UI validation предотвратит, но fallback alert |
| `9` | Rate limit | Retry с backoff |

Все ответы Meta содержат `error.message`, `error.type`, `error.code`, `error.error_subcode` — логировать все 4 для debugging.

## Pseudo-implementation

```typescript
// /lib/social/instagram.ts

const IG_API = 'https://graph.facebook.com/v21.0';

async function sendToInstagram(post: SocialPost, token: string, igUserId: string) {
  const captionFull = `${post.ig_caption}\n\n${post.ig_hashtags || ''}`.trim();
  const media = post.media_urls;

  if (media.length === 0) {
    throw new Error('instagram_no_media: IG requires at least 1 image');
  }

  let containerId: string;

  if (media.length === 1) {
    const res = await igPost(`${IG_API}/${igUserId}/media`, {
      image_url: media[0],
      caption: captionFull,
      access_token: token,
    });
    containerId = res.id;
  } else {
    // Carousel: создать children, потом parent
    const childIds: string[] = [];
    for (const url of media) {
      const childRes = await igPost(`${IG_API}/${igUserId}/media`, {
        image_url: url,
        is_carousel_item: 'true',
        access_token: token,
      });
      childIds.push(childRes.id);
    }
    const parentRes = await igPost(`${IG_API}/${igUserId}/media`, {
      media_type: 'CAROUSEL',
      children: childIds.join(','),
      caption: captionFull,
      access_token: token,
    });
    containerId = parentRes.id;
  }

  // Подождать что контейнер готов (опционально, обычно мгновенно для image)
  await sleep(2000);

  // Publish
  const publishRes = await igPost(`${IG_API}/${igUserId}/media_publish`, {
    creation_id: containerId,
    access_token: token,
  });

  return { media_id: publishRes.id };
}

async function igPost(url: string, params: Record<string, string>) {
  const body = new URLSearchParams(params).toString();
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body,
  });
  const data = await res.json();
  if (data.error) {
    throw new Error(`instagram_failed: [${data.error.code}] ${data.error.message}`);
  }
  return data;
}
```

## Testing

Для dev-окружения создать **отдельный Test IG Business Account** (или использовать тестовый под App Roles). Не тестить на проде `@traffnews_ig`.

Test connection: `GET {IG_API}/{ig-user-id}?fields=username&access_token={token}` → должен вернуть `{ id, username }`.
