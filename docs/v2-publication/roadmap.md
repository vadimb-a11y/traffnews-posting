# Roadmap

## MVP (v1) — публикация работает

Скоуп: ручная публикация в TG + IG из дашборда. Минимум features чтобы SMM мог жить с этим.

**Включено:**
- ✅ Страница `/social` в Dashboard
- ✅ Табы: Drafts, Published, Sources, Settings (Radar и Scheduled — в v2)
- ✅ Post editor: internal title, TG/IG captions, media upload (Supabase Storage), hashtags
- ✅ `[Publish now]` — синхронная публикация в TG и/или IG
- ✅ Settings: ввод TG Bot Token + IG Access Token (зашифрованно), test connection
- ✅ Encryption AES-256-GCM для tokens
- ✅ HTML sanitization captions
- ✅ Все hard rules из `docs/hard-rules.md`
- ✅ Audit log
- ✅ i18n EN/UK

**Не включено:**
- ❌ RSS Radar
- ❌ Scheduled (только Publish now)
- ❌ Calendar view
- ❌ AI helpers
- ❌ Analytics
- ❌ Контент-календарь

**Acceptance criteria:**
- SMM может зайти в `/social`, создать черновик, загрузить картинку, написать caption, нажать Publish — пост появляется в `@traffnews` и/или `@traffnews_ig`
- Если что-то падает — внятная ошибка в UI, состояние поста = `failed`, можно повторить
- Tokens защищены, plaintext не утекает в логи/responses
- Один cron-job: `cron_refresh_ig_token` (раз в сутки)

**Оценка:** 3-5 рабочих дней одного fullstack разработчика, знакомого с Dashboard codebase.

---

## v2 — RSS Radar + Scheduled

**Добавляется:**
- Tab **Radar**: лента RSS-источников (traffnews.com + конкуренты)
- Tab **Scheduled**: посты с `publish_at` в будущем, обратный отсчёт
- `[Create post from this article]` в Radar → пред-заполненный draft
- Cron `cron_rss_poll` каждые 30 мин
- Cron `cron_publish_scheduled` каждую минуту
- CRUD `/social/sources` для RSS-подписок
- Calendar view (toggle к табу Scheduled, через `react-big-calendar` или shadcn calendar)

**Acceptance:**
- SMM добавляет 3-5 RSS источников (свой + конкуренты)
- Каждые 30 минут новые статьи появляются в Radar
- SMM кликает на статью → видит редактор с заполненными полями
- SMM может поставить пост на 21:00 завтра — в 21:00 он публикуется автоматически

**Оценка:** 2-3 дня.

---

## v3 — AI helper в редакторе

**Добавляется кнопка** «✨ AI helper» в редакторе поста, открывает дропдаун:

- **Rewrite TG caption** — переписать в дерзком стиле, добавить эмодзи
- **Rewrite IG caption** — адаптировать под IG (короче лид, plain текст)
- **Generate hashtags for IG** — 20 релевантных тегов
- **Translate to UK** — перевод (для будущего UK-канала если будет)
- **Suggest title** — из RSS-статьи

Все вызовы — через OpenClaw Gateway. Не через прямой API.

```
POST {OPENCLAW_GATEWAY_URL}/v1/chat/completions
Authorization: Bearer {OPENCLAW_AUTH_TOKEN}

{
  "model": "anthropic/claude-haiku-4-5",
  "messages": [
    { "role": "system", "content": "{rewrite system prompt}" },
    { "role": "user", "content": "{current caption}" }
  ]
}
```

UI: кнопка → loading spinner → результат вставляется в поле (или предлагается diff: original vs AI-suggestion с кнопками Accept / Reject).

**Acceptance:**
- SMM пишет черновую версию caption, жмёт «Rewrite TG» — за 3-5 сек получает улучшенную версию в стиле канала
- Можно отменить и вернуть исходник
- Нулевая утечка tokens — всё через gateway

**Оценка:** 2-3 дня + время на тюнинг системного промпта.

---

## v4 — AI carousels через D:\Prog\SMM

Самая амбициозная фича. Использовать ваш существующий Java pipeline для генерации брендовых карусель-карточек.

**Архитектура:**
- `D:\Prog\SMM` оборачивается в HTTP-сервис (Spring Boot endpoint `POST /generate-carousel`)
- Deployed как контейнер рядом с Dashboard на VPS Ultrahost
- В редакторе кнопка «🎨 Generate carousel» — открывает диалог:
  - Topic / тезисы (можно сгенерить из caption через AI v3)
  - Slide count (5-10)
  - Style preset (если несколько)
- Backend Dashboard вызывает `D:\Prog\SMM` HTTP сервис, получает массив PNG, загружает в Supabase Storage, проставляет `media_urls`

**Integration contract:**
```
POST http://smm-pipeline:8080/generate-carousel
{
  "topic": "Сколько платит Рутуб в 2026",
  "tezisy": ["RPM 50-120 руб", "выплаты раз в месяц", ...],
  "slides": 7,
  "brand": "traffnews",
  "format": "1080x1350"
}

Response:
{
  "ok": true,
  "images": ["data:image/png;base64,...", ...] | ["https://temp-url/...png", ...]
}
```

**Зависимости:**
- Решить как `D:\Prog\SMM` Java выкатывается на Ultrahost (Docker / bare JVM)
- TLS / auth для internal HTTP вызовов
- Free disk space на VPS для temporary рендеров

**Оценка:** 1-2 недели (большая интеграция).

---

## v5+ — backlog

Идеи на будущее, не приоритизировано:

- **Analytics:** Views/likes для published постов, weekly digest
- **A/B testing:** Две версии caption, AI выбирает лучшую по early engagement
- **Multi-account:** Несколько TG каналов / IG аккаунтов (под разные бренды)
- **Twitter/X integration:** ещё одна платформа
- **LinkedIn:** для B2B контента
- **Threads (Meta):** новый канал Meta
- **Content calendar:** drag-drop calendar view с цветовой кодировкой типов постов
- **Templates:** шаблоны постов (Offer / Event / Roundup), SMM выбирает → пред-заполненный draft
- **Approve flow:** если приходит второй редактор — двухуровневый approve (junior пишет → senior approve)
- **Comments management:** moderate replies в TG/IG из дашборда
- **CSV import/export** постов для миграции/backup

## Migration to OpenClaw module status

Когда MVP в проде и юзают неделю-две — поднять из `Проекти / Гіпотези` → `Modules` (как WPCNT-02). Создать ADR с финальной архитектурой, присвоить код **SOCIAL-04**.
