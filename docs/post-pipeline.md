# Post Pipeline Design

Пайплайн генерации статического post-bundle. Параллельная ветка к существующему video-pipeline (`D:\Prog\SMM`). Не отдельный проект — расширение.

## Pipeline

```
INPUT (один из):
  - traffnews.com article URL
  - topic-prompt string
  - RSS item GUID (когда подключим RSS Radar в v2)
       │
       ▼
┌─────────────────────────────────────┐
│ TopicResearcher  (REUSE)            │
│ - fetch article (traffnews.com)     │
│ - web_search для контекста          │
│ - extract: facts, numbers, quotes   │
│ Output: research.json               │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ PostDirector  (NEW)                 │
│ Model: gpt-4o (как у DirectorAgent) │
│ Input: research.json + scenario_brief│
│ Output: post_brief.json             │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ Per-sentence clarity-check          │
│ (manual / automated)                │
│ - 7 правил из SMM CLAUDE.md         │
│ - REWRITE failed sentences          │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ VIEWER-WALKTHROUGH (mental pass)    │
│ - читать caption, представлять slide│
│ - tone matching (threat ≠ money UI) │
│ - reject conflicts BEFORE render    │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ PostSlideExecutor  (NEW)            │
│ Для каждого slide:                  │
│ - ImagePromptBuilder (REUSE)        │
│ - render image (HF/Recraft/SDXL)    │
│ - apply brand DNA                   │
│ - vision-verify intent              │
│ Output: PNG 1080×1350 per slide     │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ PostBundleAssembler  (NEW)          │
│ - mkdir post_bundles/<ts>_<slug>_<h>│
│ - write tg.md, ig.md, hashtags-*.txt│
│ - copy slide_*.png                  │
│ - write bundle.json metadata        │
└─────────────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│ PostQA  (NEW)                       │
│ - vision-check slides vs intent     │
│ - text legibility scan              │
│ - brand DNA preserved               │
│ - eyes-check flag (human required)  │
└─────────────────────────────────────┘
       │
       ▼
OUTPUT: ready bundle/, status=ready_for_review
```

## PostDirector — output structure

```json
{
  "topic": "Сколько платит Рутуб в 2026",
  "source_url": "https://traffnews.com/uncategorized/skolko-platit-rutub/",
  "world": "Studio Anchor",                   // выбор brand-world, как в video pipeline
  "tone": "educational",                       // educational | threat | opportunity | curiosity
  "tg_caption": "💸 <b>Сколько платит Рутуб в 2026</b>\n\nРеальные цифры...",
  "tg_hashtag": "#полезное",
  "ig_caption": "💸 Сколько платит Рутуб в 2026\n\nРеальные цифры...",
  "ig_hashtags": "#арбитраж #cpa #affiliate #трафик #вебмастер ...",
  "slides": [
    {
      "idx": 1,
      "role": "hook",
      "text": "Сколько платит Рутуб в 2026",
      "subtext": "Реальные цифры",
      "visual_intent": "big_number",
      "visual_query": "50-120 ₽",
      "image_prompt": "...",
      "tone": "educational"
    },
    {
      "idx": 2,
      "role": "fact",
      "text": "RPM 50-120 ₽",
      "subtext": "за 1000 просмотров",
      "visual_intent": "big_number",
      "image_prompt": "...",
      "tone": "neutral"
    },
    {
      "idx": 3,
      "role": "context",
      "text": "Выплаты раз в месяц",
      "subtext": "после 10 000 ₽",
      "visual_intent": "text_card iconed",
      "image_prompt": "...",
      "tone": "neutral"
    },
    ...
    {
      "idx": 7,
      "role": "cta",
      "text": "Полный разбор",
      "subtext": "на TRAFFNEWS",
      "visual_intent": "logo_sting outro",
      "image_prompt": "...",
      "tone": "brand"
    }
  ]
}
```

## Slide visual_intent types

Аналогично shot_list в видео-pipeline, но адаптировано:

| Intent | Описание | Layout |
|---|---|---|
| `big_number` | Крупное число + подпись | Centered number 240pt + subtext |
| `text_card numbered` | Список 3-5 пунктов | Vertical list with numbered bullets |
| `text_card iconed` | Текст + иконка | Icon left + text right |
| `quote_block` | Цитата с автором | Quote + author + source |
| `comparison_split` | Сравнение A vs B | 2-column split |
| `logo_sting outro` | Финальный slide с brand | Logo + tagline + CTA |
| `hook` | Slide 1 — крючок | Bold title + emoji |
| `image_full` | Полноэкранная картинка с overlay | Image + brand frame |

## Slide layout (1080×1350 — IG carousel ratio)

```
┌────────────────────────────┐  ← 0
│  [brand header: logo + №] │   ← 0-100   safe top
│                            │
│                            │
│                            │
│   [content zone]           │   ← 100-1200 main visual / text
│                            │
│                            │
│                            │
│                            │
│  [brand footer: site URL]  │   ← 1200-1350 safe bottom
└────────────────────────────┘  ← 1350
```

Inviolable zones для статики (отличаются от видео):
- **Top safe:** y=0..100 — logo + slide number (1/7, 2/7, ...)
- **Bottom safe:** y=1200..1350 — site URL `traffnews.com`
- **Content zone:** y=100..1200 — основной визуал/текст

В видео-пайплайне inviolable bottom = 480px под субтитры. В статике у нас нет субтитров → safe-zone меньше, контент-зона больше.

## Reuse map — что из SMM использовать

| Class из SMM | Где живёт | Как использовать в post-pipeline |
|---|---|---|
| `TopicResearcher` | `research/` | Reuse 1-в-1 |
| `DirectorAgent` | `director/` | Refactor: вынести общую часть в `BaseDirector`, унаследовать `PostDirector` |
| `ImagePromptBuilder` | `director/` | Reuse, тот же `Fact.displaySingle()`, тот же `Scene` enum, brand-blacklist injection |
| Brand DNA constants (цвета, шрифты) | (поискать где сейчас) | Reuse |
| Vision-verify (gpt-4o-mini) | `executor/` | Reuse |
| `ShotExecutor` | `executor/` | Не reuse — слишком video-specific. Свой `PostSlideExecutor` |
| `BrandedFinisherHF` | `finisher/` | Не нужен (нет видео-склейки) |

## Не reuse — что специфично для статики

- `PostSlideExecutor.java` — рендер одной карточки 1080×1350. Опции реализации:
  1. **HyperFrames templates** (если есть готовые карточечные templates) — best для brand consistency
  2. **Recraft v3 via Replicate** — text fidelity лучшее (помним из CLAUDE.md global rules)
  3. **Java-нативный рендер** через Java2D / Skija — для шаблонов с фиксированной структурой (number+subtext) надёжнее AI-генерации
  4. **Гибрид:** Java2D для каркаса (brand frame, header, footer), AI для центрального визуала когда нужен фоновый image
- `PostBundleAssembler.java` — упаковка bundle (file naming, JSON metadata)
- `PostQA.java` — vision-проверка slides + text legibility

## Acceptance critereria (Pipeline MVP)

Дан URL статьи с traffnews.com → за < 5 минут на выходе **bundle-папка** где:
1. `tg.md` соответствует 5-block structure, проходит clarity-check
2. `ig.md` — адаптированный (без HTML-ссылок), более развёрнутый
3. `hashtags-tg.txt` — один навигационный хэштег
4. `hashtags-ig.txt` — 15-25 SEO-релевантных хэштегов
5. `slide_01.png ... slide_NN.png` — 5-10 карточек 1080×1350, brand DNA preserved, текст читабелен на мобильном
6. `bundle.json` — metadata (topic, source URL, generated_at, slide_count, status, qa_flags)

Дальше — SMM-щик берёт папку, постит вручную в TG-канал и IG-аккаунт. Публикация автоматизируется в v2 (см. `docs/v2-publication/`).
