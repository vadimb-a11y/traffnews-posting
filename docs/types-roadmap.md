# 5 TG Post Types — Roadmap

Концепция от **Дарии Г.** (SMM, 2026-05-11). 5 типов TG-постов, каждый со своим пайплайном входа.

| # | Тип | Источник входа | Сложность | Очерёдность |
|---|---|---|---|---|
| **5** | **Вакансии** | Сырой текст вакансии (paste / URL) | ⭐ | **MVP** ← начинаем здесь |
| **2** | Дайджесты недели | Свой канал @traffnews за неделю, фильтр по тегу `#новости` | ⭐⭐ | 2-й |
| **3+4** | Подборки сервисов + AI/tool обзоры | База инструментов (Дария ведёт?) + страницы продуктов | ⭐⭐ | 3-й (объединить) |
| **1** | Новостные посты | RSS-список внешних источников | ⭐⭐⭐ | 4-й |

## Type 1 — Новостные посты (рерайт инфоповодов)

**Дария:** «ИИ собирает инфоповоды, сокращает статьи, пишет короткие TG-форматы. Я должна собрать список источников, где ИИ будет смотреть, анализировать и собирать сок.»

### Что нужно от Дарии
- Список **3-10 источников** для мониторинга. Возможные форматы:
  - RSS-фиды (легко: `affiliateguide.com/feed/`, `partnerkin.com/feed/` и т.п.)
  - Telegram-каналы конкурентов (сложнее: нужен TG-клиент с user-аккаунтом для чтения, потому что bot-аккаунты не могут читать чужие каналы)
  - Telegram-каналы партнёров где есть свежие апдейты
  - Сайты без RSS (последний resort — нужен scraper)

### Pipeline (предварительно)
```
Список источников (DB)
       ↓
NewsAggregator (cron every 30 min)
  - poll RSS / TG / scrape
  - dedup по URL/guid
  - сохранить в news_items
       ↓
NewsScorer (filter)
  - выкинуть оффтоп (не affiliate / арбитраж)
  - выкинуть свои traffnews посты
  - оставить ≤5 топов в день
       ↓
NewsDirector (gpt-4o)
  - читает 1 item → рерайт в TG-стиле
  - 3-block (HOOK / FACTS / CTA)
  - 200-500 chars
       ↓
SlideExecutor (опционально)
       ↓
Bundle: news_<ts>_<slug>_<hash>/
```

**Препятствия:**
- Чтение TG-каналов конкурентов через bot невозможно. Нужен либо user-аккаунт через Telethon/Pyrogram (Python, не Java), либо паблик RSS-мирроры этих каналов
- Дедупликация инфоповодов (одна и та же новость в 3 источниках одновременно)
- Anti-fabrication: рерайт не должен искажать факты

## Type 2 — Дайджесты недели

**Дария:** «Он должен собирать инфу с нашего тг канала за неделю по тегу #новости и собирать постик.»

### Что нужно от Дарии
- Конвенция: помечать новости в @traffnews хэштегом `#новости`
- Доступ к истории канала (через Bot API: `getChatHistory` не существует, но Bot Token может слушать channel updates и сохранять в БД)
- Альтернатива: использовать `traffnews.com/feed/` (RSS своего сайта) вместо канала

### Pipeline
```
own_channel_archive (DB)         OR        traffnews.com/feed/
       ↓                                          ↓
       └─── WeeklyDigestCollector ───────────────┘
                  filter: last 7 days, has #новости
                         ↓
                  DigestDirector (gpt-4o)
                  - 5-7 пунктов
                  - один объединяющий нарратив
                  - links на каждый
                         ↓
                  SlideExecutor: 1-2 slides
                  - cover-slide (week of XX-XX мая)
                  - bullets (5-7 пунктов)
                         ↓
                  Bundle: digest_2026-W19_/
```

**Trigger:** cron каждую пятницу 16:00 МСК

## Type 3+4 — Подборки сервисов + AI/tool обзоры

**Дария:** «Подборки: ИИ формирует списки инструментов/сервисов и краткие описания. AI/tool обзоры: автоматическое создание описаний функций и преимуществ сервисов. Это наверное тоже к подборкам можно отнести.»

### Что нужно от Дарии
- **База инструментов** — таблица в Notion / Sheet / БД с полями:
  - name, url, category (трекер / антидетект / прокси / TDS / ...), description, screenshot_url
  - Дария ведёт это вручную? или мониторит affiliate-блоги топов?
- **Темы подборок** — «Топ-5 трекеров мая», «Антидетект-браузеры под VK Ads», и т.п.

### Pipeline (комбинированный)
```
INPUT: {topic: "Топ-5 антидетектов", items: [tool_id_1, tool_id_2, ...]}
       OR
       {tool_id: "octobrowser", deep_dive: true} — для одиночного обзора
       ↓
ToolDataCollector
  - fetch tool URLs → meta description / features
  - opt: screenshot via screenshotone API
       ↓
RoundupDirector (gpt-4o)
  - подборка: 1 пост + carousel где каждый slide = 1 инструмент
  - обзор: 1 пост + 5-slide deep-dive (что делает / плюсы / минусы / цена / where-to-buy)
       ↓
SlideExecutor
       ↓
Bundle: roundup_<ts>_<slug>/ или review_<ts>_<tool>/
```

## Type 5 — Вакансии ✅ **MVP**

См. **`docs/mvp-vacancies.md`** для полного спека.

## Design principle: каждый тип владеет своими правилами

Каждый из 5 типов **отдельно** определяет:

1. **Slide count** — сколько слайдов в карусели (вакансия=5, дайджест=1-2, подборка=N+1, обзор=5, новости=2-3)
2. **Slide templates** — какие layout'ы используются (`big_number` для дайджеста, `tool_card` для подборки, `vacancy_hook` для вакансии)
3. **Visual tone** — палитра-акцент и mood (вакансия=professional, новости=urgent, подборка=catalog-like, обзор=informational)
4. **Caption structure** — формат текста (вакансия: bullets requirements/benefits; новости: HOOK/FACTS/CTA; дайджест: интро+5-7 пунктов)
5. **Hashtag preset** — свой набор (вакансия: `#вакансия #remote`; новости: `#новости`; подборка: `#инструменты #подборка`)
6. **Validation rules** — что считается готовым к публикации (вакансия должна иметь contact, новость должна иметь источник, и т.д.)

Каждый тип получает свой doc в `docs/type-*.md`:

- [`docs/mvp-vacancies.md`](./mvp-vacancies.md) ← MVP, детальный спек
- `docs/type-digest.md` ← TBD
- `docs/type-roundup.md` ← TBD (объединить с `type-review.md`?)
- `docs/type-review.md` ← TBD
- `docs/type-news.md` ← TBD

## Общий backbone (reuse across types)

Что одинаково для всех типов и **не дублируется**:

| Класс | Spec |
|---|---|
| `BaseDirector` (gpt-4o client, JSON parse, retry) | `docs/integration-plan.md` |
| `ImagePromptBuilder` | (in `D:\Prog\SMM\`) |
| `BundleWriter` | `docs/bundle-spec.md` |
| `SlideRenderer` interface | `docs/post-pipeline.md` |
| `Java2DSlideRenderer` (рендер примитивов: text-card, big_number, bullet-list, logo-frame) | TBD |
| Vision-verify (gpt-4o-mini) | (reuse from SMM video pipeline) |
| Brand DNA constants (цвета, шрифты, отступы) | (existing in SMM) |
| `BundleQA` framework | `docs/bundle-spec.md` (validation rules) |

Каждый тип реализует:
- `XxxExtractor` (parses input → structured POJO)
- `XxxDirector extends BaseDirector` (свой prompt, свой `XxxBrief` POJO)
- `XxxSlideTemplates` (свои layout-конфиги для общего `Java2DSlideRenderer`)

Бойлерплейт минимизирован — типы отличаются ровно где они должны отличаться, не там где можно reuse.
