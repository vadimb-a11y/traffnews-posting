# Architecture — Make.com + HCTI (htmlcsstoimage.com) Cloud Pipeline

Полная картина: сервисы, потоки данных, JSON-схемы, переменные.

## High-level

```
┌────────────────────────────────────────────────────────────┐
│  ОБЛАКО (на компе пользователя — ничего кроме браузера)    │
│                                                             │
│  ┌─────────────────┐    ┌──────────────────┐               │
│  │  Make.com       │    │  apitemplate.io  │               │
│  │  Scenario       │    │  9 HTML templates│               │
│  │  6 nodes        │    │  (по visual_intent)              │
│  └────────┬────────┘    └──────────▲───────┘               │
│           │ HTTP                   │ HTTP                  │
│           └───────────────────────┘                         │
│                                                             │
│  ┌─────────────────┐    ┌──────────────────┐               │
│  │  OpenAI API     │    │  Replicate API   │               │
│  │  gpt-4o         │    │  Recraft v3      │               │
│  │  PostDirector   │    │  Retrofuture bg  │               │
│  └─────────────────┘    └──────────────────┘               │
│                                                             │
│  ┌─────────────────┐                                       │
│  │  Telegram Bot   │                                       │
│  │  sendMediaGroup │                                       │
│  │  → @traffnews   │                                       │
│  └─────────────────┘                                       │
│                                                             │
└────────────────────────────────────────────────────────────┘
```

## End-to-end flow (что происходит при триггере)

### Триггеры

- **Auto (v2)**: Make poll RSS `https://traffnews.com/category/news/feed/` каждые 15 минут
- **Manual (v1)**: Make webhook URL, POST с `{ "article_url": "..." }`

### Шаги сценария (6 нод)

#### NODE 1 — HTTP: Fetch article
- **Module**: `HTTP > Make a request`
- **Method**: GET
- **URL**: `{{trigger.article_url}}`
- **Parse response as**: Text
- **Output**: `article_html` (HTML страницы)

#### NODE 2 — OpenAI: PostDirector
- **Module**: `OpenAI (ChatGPT, Whisper, DALL-E) > Create a Completion (GPT and o-series models)`
- **Model**: `gpt-4o`
- **Messages**:
  - **System**: содержимое `docs/director-prompt-article.md` (целиком)
  - **User**: `Article URL: {{trigger.article_url}}\n\nArticle HTML:\n{{node1.article_html}}`
- **Response format**: `json_object`
- **Max tokens**: 4000
- **Temperature**: 0.7
- **Output**: `brief` (JSON, схема ниже)

**JSON schema от PostDirector:**
```json
{
  "tg_caption": "🤖 ИИ официально стал причиной #1...\n\n<a href=\"...\">читать материал →</a>\n\n| @traffnews | #полезное",
  "tg_hashtag": "#полезное",
  "article_url": "https://traffnews.com/news/...",
  "topic_label": "Сокращения 2026",
  "year": "2026",
  "slides": [
    {
      "idx": 1,
      "visual_intent": "cover",
      "title": "ИИ ПРОТИВ ОФИСА",
      "subtitle": "Кого режут первым в 2026",
      "image_prompt": "office workers silhouettes..."
    },
    {
      "idx": 2,
      "visual_intent": "big_number",
      "big_number": "26%",
      "subline_1": "всех увольнений в США в апреле",
      "subline_2": "2026 — напрямую из-за ИИ",
      "secondary_yellow": "21 490 рабочих мест",
      "secondary_white": "за один месяц.",
      "body_text": "И это число будет только расти..."
    },
    /* … остальные slides по visual_intent: quote_block, bullet_list, 
       numbered_list, service_list, compare_split, faq, outro_cta */
  ]
}
```

Каждый slide имеет:
- `idx` — номер 1..N
- `visual_intent` — один из 9 типов, определяет какой HTML-шаблон Make подставит
- Остальные поля — переменные конкретного шаблона

#### NODE 3 — Replicate: retrofuture background
- **Module**: `HTTP > Make a request` (Replicate нет нативного модуля)
- **Method**: POST
- **URL**: `https://api.replicate.com/v1/models/recraft-ai/recraft-v3/predictions`
- **Headers**:
  - `Authorization: Bearer {{REPLICATE_TOKEN}}`
  - `Content-Type: application/json`
  - `Prefer: wait`
- **Body**:
  ```json
  {
    "input": {
      "prompt": "Abstract retrofuturistic 1980s vaporwave background, deep dark purple base color hex 1a0d3a, low-poly wireframe mountain silhouettes on horizon, perspective grid floor receding to vanishing point, distant glowing sun semi-circle behind mountains in soft yellow hex e8f045, atmospheric purple haze, subtle starfield, very subtle CRT scanlines, sci-fi blueprint feel, minimal pure decorative texture, ABSOLUTELY NO TEXT NO LETTERS NO NUMBERS NO WORDS NO TYPOGRAPHY NO LOGOS NO PEOPLE NO OBJECTS, purely abstract environmental background only",
      "size": "1024x1280",
      "style": "digital_illustration"
    }
  }
  ```
- **Output**: `{ "output": "https://replicate.delivery/.../bg.webp" }`
- Сохраняем `bg_image_url` для использования во всех слайдах

#### NODE 4 — Iterator: для каждого slide
- **Module**: `Flow Control > Iterator`
- **Array**: `{{node2.brief.slides}}`
- На каждой итерации — выполняется NODE 5

#### NODE 5 — HCTI: render HTML → PNG

Это **две подноды**: сначала Make строит HTML-строку с подставленными переменными, потом POST в HCTI.

**5a — Build HTML (Make Text Aggregator / Tools > Set Variable):**

Хранение шаблонов в Make. Самый простой способ — **9 переменных сценария** (Scenario settings → Variables), каждая содержит один HTML-шаблон как plain text. При запуске сценария они уже доступны.

В Iterator на каждом шаге используется Make formula:
```
{{
  switch(slide.visual_intent;
    "cover"; var.TMPL_COVER;
    "big_number"; var.TMPL_BIG_NUMBER;
    "quote_block"; var.TMPL_QUOTE;
    "bullet_list"; var.TMPL_BULLET;
    "numbered_list"; var.TMPL_NUMBERED;
    "service_list"; var.TMPL_SERVICE;
    "compare_split"; var.TMPL_COMPARE;
    "faq"; var.TMPL_FAQ;
    "outro_cta"; var.TMPL_OUTRO
  )
}}
```

Затем `replace()` для подстановки переменных слайда — для каждой переменной {{varname}} в шаблоне Make вызывает функцию `replace(html; "{{varname}}"; slide.varname)`. Это пишется как последовательность функций или через Tools > Compose a string.

**Откуда брать содержимое для Scenario Variables**: копипаст из этого репо, файлы `D:\Prog\Постинг\docs\slide-templates\slide-XX-*.html`. При обновлении шаблона — копипастим обновлённый файл в Scenario Variable. (Альтернатива на v2: push репо в GitHub public, Make делает HTTP GET к raw URL `https://raw.githubusercontent.com/.../slide-XX.html` на каждом прогоне — всегда свежая версия.)

**5b — POST в HCTI:**
- **Module**: `HTTP > Make a request`
- **Method**: POST
- **URL**: `https://hcti.io/v1/image`
- **Authorization**: Basic Auth → username = `{{HCTI_USER_ID}}`, password = `{{HCTI_API_KEY}}`
- **Body type**: Raw / JSON
- **Body**:
  ```json
  {
    "html": "{{constructed_html_body_from_5a}}",
    "css": "{{constructed_html_style_from_5a}}",
    "google_fonts": "Anton|Inter:400,500,700,900|JetBrains+Mono:700",
    "viewport_width": 1080,
    "viewport_height": 1350,
    "device_scale": 2
  }
  ```

Можно сразу присылать **целый HTML с `<style>` внутри** через поле `html` — HCTI разберёт. Тогда подноды 5a достаточно одной.

- **Output**: `{ "url": "https://hcti.io/v1/image/abc-def-...", ... }`
- Сохраняем `url` в массив для NODE 6

#### NODE 6 — Aggregator + Telegram: send carousel
- **Aggregator**: собирает все `download_url_png` в массив
- **Module**: `Telegram Bot > Send Media Group` (нативный) или `HTTP` к Bot API
- **Method** (через HTTP): POST `https://api.telegram.org/bot{{BOT_TOKEN}}/sendMediaGroup`
- **Body**:
  ```json
  {
    "chat_id": "@traffnews",
    "media": [
      { "type": "photo", "media": "https://hcti.io/v1/image/.../slide_01.png", "caption": "{{node2.brief.tg_caption}}", "parse_mode": "HTML" },
      { "type": "photo", "media": "https://hcti.io/v1/image/.../slide_02.png" },
      { "type": "photo", "media": "https://hcti.io/v1/image/.../slide_03.png" },
      { "type": "photo", "media": "https://hcti.io/v1/image/.../slide_04.png" },
      { "type": "photo", "media": "https://hcti.io/v1/image/.../slide_05.png" }
    ]
  }
  ```
- Caption указывается только на **первом** фото (TG показывает его под всей группой)
- `parse_mode: HTML` — чтобы `<a href>` ссылка кликалась

## Хранение API-ключей

Все ключи живут в **Make Connections** (зашифрованные). Не в HTTP-нодах открытым текстом, не в коде, не в репозитории.

| Сервис | Где взять | Имя Connection в Make |
|---|---|---|
| OpenAI | platform.openai.com/api-keys | `openai-traffnews` |
| Replicate | replicate.com/account/api-tokens | `replicate-traffnews` |
| HCTI | htmlcsstoimage.com/dashboard → API Keys (нужны и USER_ID и API_KEY для basic auth) | `hcti-traffnews` |
| Telegram Bot | @BotFather в Telegram | `telegram-traffnews-bot` |

## Cost model

Per post (1 carousel = 5-10 slides):
- OpenAI gpt-4o (PostDirector): ~$0.01
- Replicate Recraft v3 (1 bg per carousel): $0.05
- HCTI (на free 50 рендеров/мес): $0 если ≤7 постов/мес, иначе $14/мес для 1000 рендеров
- Make.com (на free 1000 ops/мес): $0 если ≤50 постов/мес, иначе $10.59/мес
- Telegram: $0

**Total на free tier**: ~$0.06 за пост × 7 постов = $0.42/мес. Реально — заплатишь Replicate $5-10 за месяц.

**Total после free overflow** (50+ постов/мес): ~$25-30/мес total (HCTI $14 + Make $10.59 + APIs).

## Failure modes & fallbacks

| Failure | Что делать |
|---|---|
| Replicate timeout (60s+) | Retry x1 → fallback на static gradient bg (`{{bg_image_url}} = пустая строка` → CSS gradient в шаблоне) |
| HCTI 5xx | Retry x2 → пометить пост failed, alert в Telegram админ-чат |
| OpenAI rate limit | Make exponential backoff (нативно поддерживает) |
| Telegram media too large (>10MB) | На уровне HCTI выставить quality=80 jpg вместо png |
| Caption >1024 chars | PostDirector промпт уже принуждает лимит; если получит больше → truncate в Make text function |

## v2 / future

- Авто-постинг **с approve-step**: Make сначала шлёт preview в админ-чат Telegram с кнопками «Опубликовать / Отклонить», только при approve — постится в @traffnews
- Дашборд CS Dashboard `/social` страница (Next.js): кнопка «Сгенерировать пост» дёргает Make webhook
- Instagram trek: добавить ноду для Instagram Graph API (2-step container → publish), отдельный caption (без `<a href>`), 15-25 хэштегов
- Остальные 4 типа постов (vacancies/digest/roundup/news) — каждый = отдельный Make-сценарий со своим PostDirector промптом и своим набором HTML-шаблонов
