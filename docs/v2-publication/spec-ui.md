# /social UI Spec

Страница `/social` в Dashboard. Next.js 16 App Router, Server Components by default, `'use client'` только где нужна интерактивность (формы, табы, модалка редактора). shadcn/ui + Tailwind 4. i18n через `next-intl` (EN default, UK подготовлено).

## Layout страницы

```
┌──────────────────────────────────────────────────────────────────┐
│ [Dashboard header — общий для всех страниц]                      │
├──────────────────────────────────────────────────────────────────┤
│  Social                                       [+ Create post]    │
│                                                                   │
│  ┌─ Tabs ───────────────────────────────────────────────────┐   │
│  │  [● Radar (12)]  [ Drafts (3) ]  [ Scheduled (5) ]       │   │
│  │  [ Published ]   [ Sources ]   [ Settings ]              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  [контент текущего таба]                                          │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘
```

URL pattern:
- `/social` → редирект на `/social/radar`
- `/social/radar`
- `/social/drafts`
- `/social/scheduled`
- `/social/published`
- `/social/sources`
- `/social/settings`

Каждый таб — отдельный Server Component. Tab-switcher — `<Tabs />` из shadcn.

## Tab: Radar

Лента свежих статей из всех `social_rss_sources` где `is_active = true`. Источник данных: `GET /api/social/rss-items?is_read=false&limit=50`.

```
┌──── Radar — свежие статьи ─────────────────────────────────────┐
│                                                                  │
│  [Source filter: ▼ All / Own / Competitors]   [↻ Refresh]       │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ [NEW]  Сколько платит Рутуб в 2026                       │  │
│  │        traffnews.com · 11 мая, 21:00                     │  │
│  │        Реальные цифры, формулы, как зарабатывать...     │  │
│  │        [Open original →]    [Create post →]    [✓ Read]  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ [NEW]  Top 10 CPA networks 2026                          │  │
│  │        affiliateguide.com · 10 мая, 14:30                │  │
│  │        ...                                                │  │
│  │        [Open original →]    [Create post →]    [✓ Read]  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

Карточка item — `<Card />` shadcn. Бейджи: `[NEW]` (если `is_read=false`), `[USED]` (если `is_used=true` — из этого item уже сделан пост).

Действия:
- **Open original** → external link в новой вкладке + `PATCH /api/social/rss-items/[id] { is_read: true }`
- **Create post** → `POST /api/social/rss-items/[id]/create-post` → редирект на `/social/drafts/[new_post_id]` (откроется редактор с пред-заполненными полями)
- **✓ Read** → `PATCH /api/social/rss-items/[id] { is_read: true }` (убрать из ленты без открытия)

## Tab: Drafts

Список постов где `status = 'draft'`. Source: `GET /api/social/posts?status=draft`.

```
┌──── Drafts ──────────────────────────────────────────────────────┐
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Сколько платит Рутуб в 2026                                │  │
│  │ TG ✓  IG ✓     1 image     Создан 11 мая                   │  │
│  │ [Edit] [Publish now] [Schedule] [Delete]                    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Розыгрыш билетов MAC 2026                                  │  │
│  │ TG ✓  IG ✗     2 images    Создан 11 мая                   │  │
│  │ [Edit] [Publish now] [Schedule] [Delete]                    │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

## Tab: Scheduled

Список где `status = 'scheduled'`, отсортирован по `publish_at asc`. Карточка показывает дату/время публикации, обратный отсчёт. Действия: Edit / Cancel schedule (→ draft) / Delete.

Опциональный календарный view (toggle Grid/Calendar) — в v2.

## Tab: Published

История. Source: `GET /api/social/posts?status=posted&limit=50&order=published_at:desc`.

Колонки: title, дата публикации, бейджи платформ (TG ✓ + ссылка на сообщение, IG ✓ + ссылка), created_by. Кликабельно — открывает read-only превью.

## Tab: Sources

CRUD `social_rss_sources`. Простая таблица: name, URL, is_own (badge), last_polled_at, [Delete]. Кнопка `[+ Add source]` — модалка с полями `name`, `url`, `is_own (checkbox)`.

## Tab: Settings

**Доступ — только admin.** Управление `social_secrets`.

```
┌──── Settings ────────────────────────────────────────────────────┐
│                                                                    │
│  Telegram                                                          │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Bot:           @traffnews_post_bot                          │  │
│  │ Channel:       @traffnews                                   │  │
│  │ Token:         [●●●●●●●●●●●●●●●● (hidden)]    [↻ Update]    │  │
│  │ Status:        ✓ Connected · Tested 2 min ago               │  │
│  │ [Test connection]                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  Instagram                                                         │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ Business account ID:  17841408449121234                     │  │
│  │ Page ID:              1234567890                            │  │
│  │ Token expires:        in 53 days                            │  │
│  │ Token:                [●●●●●●●●●●●● (hidden)]   [↻ Update]   │  │
│  │ Status:               ✓ Connected · Auto-refresh enabled    │  │
│  │ [Test connection] [Refresh now]                              │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
└──────────────────────────────────────────────────────────────────┘
```

Update-токена открывает модалку — input для plaintext token + Save. На бэке сразу шифруется и кладётся в `social_secrets.encrypted_token`. Plaintext в БД **никогда**.

## Post Editor (модалка / drawer)

Открывается из:
- `[+ Create post]` (пустая форма)
- `[Edit]` в Drafts/Scheduled
- `Create post` из Radar (пред-заполняется из RSS item: `title` = item.title, `tg_caption` = item.title + item.description + link, `media_urls` = [item.cover_image_url], `source_url` = item.link, `source_rss_item_id` = item.id)

Layout — `<Sheet />` (drawer справа) или `<Dialog />` (модалка по центру). Drawer лучше для длинного контента.

```
┌──── Edit post ───────────────────────────────────────────────────┐
│                                                          [×]      │
│  Internal title*                                                   │
│  [____________________________________________]                   │
│                                                                    │
│  Source URL (опционально, для трекинга)                            │
│  [https://traffnews.com/...___________________]                   │
│                                                                    │
│  ─────────── Telegram (@traffnews) ───────────                    │
│  ☑ Publish to Telegram                                             │
│  Caption (HTML allowed: <b>, <i>, <a href>)                        │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ 💸 Думаешь о пассивном доходе? Скорее всего, ты...        │    │
│  │                                                            │    │
│  │ Читай на TRAFFNEWS 👉 [link]                              │    │
│  └──────────────────────────────────────────────────────────┘    │
│  342 / 4096 chars                                                  │
│  Hashtag: [ #полезное ▼ ]                                          │
│                                                                    │
│  ─────────── Instagram (@traffnews_ig) ───────────                │
│  ☑ Publish to Instagram          (requires ≥1 image)               │
│  Caption (plain text + emoji)                                      │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │ ...                                                        │    │
│  └──────────────────────────────────────────────────────────┘    │
│  1024 / 2200 chars                                                 │
│  Hashtags                                                           │
│  [#арбитраж #cpa #affiliate #трафик #вебмастер ...]               │
│  17 / 30 hashtags                                                  │
│                                                                    │
│  ─────────── Media ───────────                                    │
│  [+ Upload images]   (drag-drop поддержка)                         │
│                                                                    │
│  ┌──┐ ┌──┐ ┌──┐                                                   │
│  │1 │ │2 │ │3 │  (можно переставлять drag, удалять)                │
│  └──┘ └──┘ └──┘                                                   │
│  3 / 10 images                                                     │
│                                                                    │
│  ─────────── Publishing ───────────                               │
│  ◯ Publish now                                                     │
│  ● Schedule for: [📅 12 мая 2026] [⏰ 10:00 МСК]                   │
│                                                                    │
│                                  [Save draft]  [Schedule]  [Cancel]│
└──────────────────────────────────────────────────────────────────┘
```

### Валидации (UI-level, до click Publish)

- Internal title — required, ≤ 200 chars
- Хотя бы одна платформа выбрана
- Если `publish_to_ig` — обязательно ≥ 1 image
- TG caption ≤ 4096 chars (или 1024 если есть медиа — TG лимит для caption под фото)
- IG caption ≤ 2200 chars
- Media: ≤ 10 images, форматы JPEG/PNG (для IG обязательно JPEG, конвертить на upload)
- Если schedule — `publish_at` должен быть в будущем

### Состояния поста в редакторе

| State | UI |
|---|---|
| Editing draft | [Save draft] [Schedule] [Publish now] [Cancel] |
| Editing scheduled | [Save & reschedule] [Cancel schedule (→ draft)] [Delete] |
| Read-only published | Disabled fields. [Open in TG] [Open in IG] [Duplicate as draft] |

## Компоненты shadcn

Используемые компоненты (через CLI, не редактируем вручную):
- `Tabs`, `TabsList`, `TabsTrigger`, `TabsContent`
- `Card`, `CardHeader`, `CardContent`, `CardFooter`
- `Sheet` (drawer редактора)
- `Dialog` (delete confirm, secret update)
- `Input`, `Textarea`, `Label`
- `Button`, `Badge`
- `Select` (hashtag selector)
- `Checkbox`, `RadioGroup`
- `DatePicker` (для schedule — добавить через shadcn registry)
- `Toast` для уведомлений
- `Table`, `TableRow`, `TableCell`

## Mobile

Mobile-first для просмотра, не критично для редактирования (Editor можно скрывать кнопку "+ Create post" под `md:`). Tabs на mobile — горизонтальный scroll. Card-список — vertical stack.

## i18n

Все user-facing строки — через `useTranslations('social')`. Keys в `messages/en.json` и `messages/uk.json`:

```json
"social": {
  "title": "Social",
  "tabs": {
    "radar": "Radar",
    "drafts": "Drafts",
    "scheduled": "Scheduled",
    "published": "Published",
    "sources": "Sources",
    "settings": "Settings"
  },
  "editor": {
    "title": "Edit post",
    "internalTitle": "Internal title",
    "publishToTg": "Publish to Telegram",
    "publishToIg": "Publish to Instagram",
    ...
  },
  "errors": { ... }
}
```
