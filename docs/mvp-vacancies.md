# MVP — Vacancy Post Pipeline (TG)

Первый рабочий пайплайн. Один тип поста — **вакансии**. Только Telegram. Текст + карусель.

## Почему вакансии первыми

- Простейший input: **сырой текст вакансии** (паст или URL job-board'а)
- Никакого внешнего мониторинга (RSS / других каналов) — input даётся вручную
- Чёткая структура (поля известны: компания, позиция, зарплата, требования, контакт)
- Быстрый smoke-test всей инфраструктуры (Director, SlideExecutor, BundleAssembler) на одном простом случае

## Input

Любой из:
- **Raw text** — паст текста вакансии в поле / файл
- **URL** — ссылка на job-board / страницу с описанием → fetch HTML → extract text
- **Structured form** (опционально для v1.1) — поля в форме: company, position, salary, requirements, benefits, contact

Минимально необходимый набор полей в результате extraction:
- `company` (string, required)
- `position` (string, required)
- `salary` (string или null — «$3000-5000», «по договорённости», null если не указано)
- `location` (string — «Remote», «Cyprus», «Москва/Remote»)
- `requirements` (array of strings — 3-7 пунктов)
- `tasks` (array of strings — 3-5 пунктов)
- `benefits` (array of strings — 3-5 пунктов)
- `contact` (string — `@username` / email / телеграм-handle)
- `company_logo_url` (string или null — если есть/удалось найти)

## Pipeline

```
INPUT (raw text / URL / form)
       ↓
VacancyExtractor (gpt-4o)
  prompt: "выдели поля из текста вакансии в JSON-формат"
  output: Vacancy POJO (см. fields выше)
       ↓
[Validation: required fields присутствуют?]
       ↓
VacancyDirector (gpt-4o)
  prompt: "сформируй TG-пост + brief 5 слайдов под carousel"
  output: VacancyBrief {
    tg_caption: "...",
    tg_hashtag: "#вакансия",
    slides: [5 объектов]
  }
       ↓
[Clarity-check на caption — 7 правил из SMM CLAUDE.md]
       ↓
VacancySlideExecutor
  render 5 слайдов 1080×1350:
    - slide_01: company logo + position + salary + location
    - slide_02: что нужно (requirements bullets)
    - slide_03: что делать (tasks bullets)
    - slide_04: что предлагают (benefits bullets)
    - slide_05: контакт + CTA + brand footer
       ↓
VacancyBundleAssembler
  → post_bundles/vacancy_<date>_<slug>_<hash>/
       ↓
PostQA (vision-check на 5 slides)
       ↓
OUTPUT: ready bundle
```

## Слайды — детальная структура

Все 1080×1350 PNG, brand DNA: blue-deep + yellow, Manrope/Russo One/JetBrains Mono.

### Slide 1 — Hook

```
┌────────────────────────────┐
│  [TraffNews logo]    1/5   │  ← header
│                            │
│      [company_logo]        │  ← если есть, иначе skip
│                            │
│       COMPANY NAME         │  ← Russo One, 56pt
│                            │
│   ─────────────────────    │
│                            │
│      Senior CPA Manager    │  ← Russo One, 48pt — position
│                            │
│      $3000-5000            │  ← Manrope Bold, 72pt, yellow accent
│      Remote                │  ← Manrope, 36pt, secondary
│                            │
│        traffnews.com       │  ← footer
└────────────────────────────┘
```

### Slide 2 — Requirements (что нужно)

```
┌────────────────────────────┐
│  [TraffNews logo]    2/5   │
│                            │
│      ЧТО НУЖНО             │  ← section title
│                            │
│   ─────────────────────    │
│                            │
│  ✓  3+ года в affiliate    │
│                            │
│  ✓  Опыт с гемблинг        │
│      вертикалью            │
│                            │
│  ✓  Английский B2+         │
│                            │
│  ✓  Готовность к           │
│      переезду на Кипр       │
│                            │
│        traffnews.com       │
└────────────────────────────┘
```

### Slide 3 — Tasks (что делать)

```
┌────────────────────────────┐
│  [TraffNews logo]    3/5   │
│                            │
│       ЗАДАЧИ               │
│                            │
│   ─────────────────────    │
│                            │
│  •  Управление командой    │
│     медиа-байеров          │
│                            │
│  •  Бюджет $500K+/мес     │
│                            │
│  •  ROI-оптимизация        │
│                            │
│  •  Запуск новых ГЕО       │
│                            │
│        traffnews.com       │
└────────────────────────────┘
```

### Slide 4 — Benefits (что предлагают)

```
┌────────────────────────────┐
│  [TraffNews logo]    4/5   │
│                            │
│      ЧТО ПРЕДЛАГАЕМ        │
│                            │
│   ─────────────────────    │
│                            │
│  🏝  Релокация на Кипр    │
│                            │
│  💰  Зарплата $3000-5000   │
│      + bonus до 50%        │
│                            │
│  🏥  Страховка             │
│                            │
│  ✈   4 раза в год на       │
│      конференции          │
│                            │
│        traffnews.com       │
└────────────────────────────┘
```

### Slide 5 — Apply (как откликнуться)

```
┌────────────────────────────┐
│  [TraffNews logo]    5/5   │
│                            │
│   ────────────────────     │
│                            │
│       ОТКЛИКНУТЬСЯ         │
│                            │
│       @hr_username         │  ← Manrope Bold 60pt, yellow
│                            │
│   ────────────────────     │
│                            │
│   Подробнее на нашем       │
│   канале                   │
│                            │
│        traffnews.com       │
└────────────────────────────┘
```

## TG caption формат

```html
💼 <b>{position}</b> — {company}

💰 {salary} · 📍 {location}

<b>Что нужно:</b>
• {requirement_1}
• {requirement_2}
• {requirement_3}

<b>Что предлагаем:</b>
• {benefit_1}
• {benefit_2}

Откликнуться: {contact}

Подробности в карусели ⤴️

#вакансия #арбитраж
```

Длина 600-1200 символов. Под лимит TG `sendMediaGroup` caption (1024 chars). Если перебор — сокращать bullets до 2-3 каждый.

## Bundle output

```
post_bundles/vacancy_2026-05-11_traffnews-cpa-manager_a7f3c2/
├── bundle.json
├── tg.md
├── hashtags-tg.txt
├── slide_01.png       (1080×1350)
├── slide_02.png
├── slide_03.png
├── slide_04.png
├── slide_05.png
├── extracted.json     (debug: что VacancyExtractor вытащил)
└── brief.json         (debug: что VacancyDirector вернул)
```

`bundle.json` — как в `docs/bundle-spec.md`, плюс поле `post_type: "vacancy"`.

## Что специфично vs generic post-pipeline

Vacancy-pipeline — это **специализация** общего post-pipeline. Reuse:
- `BaseDirector` (gpt-4o client wrapper, JSON parsing)
- `ImagePromptBuilder` (если нужны generated images для логотипов компаний)
- Brand DNA constants
- Vision-verify, PostQA framework
- BundleWriter

Специфично:
- `VacancyExtractor` — отдельный класс, gpt-4o с структурированным extraction prompt
- `VacancyDirector extends BaseDirector` — свой prompt и output schema (`VacancyBrief` вместо generic `PostBrief`)
- `VacancySlideExecutor` — фиксированные 5 templates (slide_01..05), не из shot_list а из known structure

## CLI usage

```powershell
cd D:\Prog\SMM

# From raw text file
java -cp scripts/java/target/classes com.traffnews.smm.post.VacancyPipelineRunner `
  --input-file vacancy_raw.txt `
  --output-dir ./post_bundles

# From URL
java -cp scripts/java/target/classes com.traffnews.smm.post.VacancyPipelineRunner `
  --input-url "https://hh.ru/vacancy/12345678" `
  --output-dir ./post_bundles
```

Output:
```
✓ Extracted: company=Traffnews, position=Senior CPA Manager, salary=$3000-5000
✓ Validation: all required fields present
✓ Director: tg_caption (847 chars), 5 slides briefed
✓ Clarity-check: 6/6 sentences PASS
✓ SlideExecutor: 5/5 slides rendered (1080×1350)
✓ PostQA: vision-pass 5/5, fabrication=pass
✓ Bundle: ./post_bundles/vacancy_2026-05-11_traffnews-cpa-manager_a7f3c2/
   status: ready_for_review
```

## Acceptance criteria (MVP)

Дан текст вакансии (paste) → за < 2 минуты на выходе bundle где:

1. `tg.md` — корректно отформатирован, проходит clarity-check, поля заполнены из исходного текста
2. `slide_01..05.png` — 5 brand-карточек 1080×1350, читабельны на мобильном
3. `hashtags-tg.txt` — релевантные хэштеги (`#вакансия #арбитраж #remote` + 2-3 контекстных)
4. Slide 1 содержит логотип компании ЕСЛИ дан, иначе fallback на крупный текст с названием
5. Никаких выдуманных фактов — Director использует только то что в исходном тексте
6. SMM-щик берёт bundle, в TG-клиенте загружает 5 slides + paste caption из `tg.md`, постит

## Что НЕ в MVP

- ❌ IG версия (IG = отдельный трек позже)
- ❌ Авто-публикация в TG (manual в v1, авто в v2 — см. `docs/v2-publication/`)
- ❌ Авто-парсинг с job-board API (только paste/URL fetch)
- ❌ Хранение вакансий в БД (bundle = single deliverable, без БД)
- ❌ Подача формы через Dashboard UI (CLI + script в v1; форма в v2)

## Следующий тип (после Vacancies)

Когда Vacancy-pipeline стабилен (3-5 живых вакансий опубликованы, фидбек от Дарии собран) — берём следующий по сложности:

1. **Вакансии** ← вы здесь (MVP)
2. **Дайджесты недели** — input от своего канала по тегу `#новости`, 1 раз в неделю
3. **Подборки + AI/tool обзоры** — нужна база инструментов
4. **Новостные посты** — RSS-мониторинг внешних источников
