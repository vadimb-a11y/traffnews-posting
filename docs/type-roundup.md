# Type 3+4 — Service Roundups & Tool Reviews (stub)

От Дарии: «ИИ формирует списки инструментов/сервисов и краткие описания. AI/tool обзоры: автоматическое создание описаний функций и преимуществ сервисов. Но это наверное тоже к подборкам можно отнести.»

**Объединяем 3+4** — это одна семья пайплайнов с двумя режимами:
- **Roundup mode** — топ-5/10 инструментов по категории
- **Review mode** — глубокий обзор одного инструмента

**Статус:** 🟦 stub. Заполнить после Vacancy + Digest.

## Открытые вопросы — нужно решить с Дарией

1. **База инструментов:**
   - Дария ведёт таблицу/Notion с инструментами? Откуда брать список?
   - Или ИИ должен сам искать топы (это рискованно — fabrication)?
2. **Темы roundups** — фиксированный календарный план («каждый понедельник — антидетекты», «каждую среду — трекеры»)? Или адресные («сделай подборку трекеров под нашу задачу X»)?
3. **Глубина review** — сколько слайдов, какие разделы (что делает / плюсы / минусы / цена / альтернативы)?
4. **Источник данных по tool**: сам сайт продукта (scrape) или taught Дарией заранее?

## Roundup mode — структура

### Input
- Topic: «Топ-5 антидетектов для VK Ads, май 2026»
- Tools list: `[octobrowser, multilogin, adspower, dolphin{anty}, gologin]` — ID из базы

### Caption
```
🛠 <b>{topic_title}</b>

Выжимка по {N} инструментам — сильные стороны, цены, фишки.

1. {tool_1.name} — {1 line}
2. {tool_2.name} — {1 line}
...

Подробности в карусели ⤴️

#подборка #инструменты #арбитраж
```

### Slides
- **slide_01** — Cover: title + count + brand frame
- **slide_02..N+1** — один слайд на инструмент:
  ```
  ┌────────────────────────┐
  │ [tool_logo]       2/6  │
  │                        │
  │   TOOL NAME            │
  │                        │
  │   Категория:           │
  │   antidetect browser   │
  │                        │
  │   Цена: от $79/мес     │
  │                        │
  │   • feature 1          │
  │   • feature 2          │
  │   • feature 3          │
  │                        │
  │   tool-website.com     │
  │                        │
  │      traffnews.com     │
  └────────────────────────┘
  ```
- **slide_N+2** — CTA: «Где использовать → reviews на traffnews.com»

## Review mode — структура

### Input
- Tool ID: `octobrowser`
- Mode: `review` (deep dive)

### Caption
```
🔍 <b>{tool_name}</b> — детальный разбор

Что делает / кому подходит / сильные стороны / минусы / альтернативы.

В карусели ⤴️ подробности по каждому пункту.

Цена: {price_summary}
Сайт: {tool_url}

#обзор #инструменты #{tool_slug}
```

### Slides (5)
- **slide_01** — Hook: tool logo + name + tagline + price
- **slide_02** — Что делает (overview + 3 main features)
- **slide_03** — Сильные стороны (3-5 bullets)
- **slide_04** — Минусы / ограничения (2-3 bullets — честно!)
- **slide_05** — Где взять (URL / куда писать) + CTA

## Visual tone

- Catalog-like (roundup mode) — structured, comparable
- Detail-rich (review mode) — bullet-heavy, infographic style
- Brand colors сохраняются, но **акцентный цвет** может варьироваться по категории (антидетекты — фиолетовый акцент, трекеры — зелёный, etc.) — TBD с Дарией

## Pipeline (набросок)

```
INPUT: { mode: roundup|review, topic|tool_id, items_count? }
       ↓
ToolDataCollector
  - fetch from base (Notion DB / Sheet / SQL)
  - opt: scrape product page для свежей цены
  - opt: screenshot via screenshotone
       ↓
RoundupDirector | ReviewDirector (gpt-4o)
       ↓
SlideExecutor (N+2 или 5 slides)
       ↓
Bundle: roundup_<ts>_<slug>/ или review_<ts>_<tool>/
```

## Зависимости

- **База инструментов** (Notion / Sheets / БД) — must-have. Дария или dev должен сделать
- Опционально: ScreenshotOne API key (для скрина продукта на slide)
- Опционально: scraper / fetch HTML для свежих цен
