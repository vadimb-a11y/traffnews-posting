# Traffnews Posting — Static Post Bundle Pipeline

**Статус:** 🟡 R&D / спецификации · код будет жить в `D:\Prog\SMM\` (расширение существующего проекта)

Параллельная ветка к существующему **video pipeline** (агент SOCL-04, видео-Reels 30с). Цель — генерация **статических post-bundles** (TG-caption + IG-caption + 5-10 brand-карусель-карточек) под `@traffnews` и `@traffnews_ig`.

## Не отдельный проект

Это **расширение D:\Prog\SMM**, не отдельная кодовая база:

```
D:\Prog\SMM\
├── (существующее, не трогать)
│   ├── CLAUDE.md
│   ├── docs/
│   ├── scripts/java/src/main/java/com/traffnews/smm/
│   │   ├── director/    ← переиспользуем (DirectorAgent, ImagePromptBuilder)
│   │   ├── research/    ← переиспользуем (TopicResearcher)
│   │   ├── executor/    ← частично переиспользуем (ShotExecutor → PostSlideExecutor)
│   │   ├── finisher/    ← частично (BrandedFinisherHF → PostFinisher)
│   │   ├── hedra/       ← НЕ нужно для статики
│   │   ├── elevenlabs/  ← НЕ нужно для статики (нет аудио)
│   │   └── ass/         ← НЕ нужно (нет видео-субтитров)
│   └── tests/
│
└── scripts/java/src/main/java/com/traffnews/smm/post/    ← НОВЫЙ ПАКЕТ
    ├── PostDirector.java        — gpt-4o → post_brief.json
    ├── PostSlideExecutor.java   — slide image generation per slide
    ├── PostBundleAssembler.java — пакует bundle/ folder
    ├── PostQA.java              — vision-check slides match topic
    └── ...

D:\Prog\Постинг\                 ← ЭТА ПАПКА: только документация и спеки
├── README.md
├── CLAUDE.md
└── docs/
    ├── post-pipeline.md          — pipeline design
    ├── bundle-spec.md            — output bundle format
    ├── integration-plan.md       — что добавляется в D:\Prog\SMM
    └── v2-publication/           — спека публикации в TG/IG (deferred)
        ├── architecture-schema.md
        ├── spec-ui.md
        ├── spec-telegram.md
        ├── spec-instagram.md
        ├── hard-rules.md
        └── roadmap.md
```

## Что на выходе

5 разных типов постов под TG (от Дарии Г., SMM):

| # | Тип | Очерёдность |
|---|---|---|
| 5 | **Вакансии** | **MVP — начинаем здесь** |
| 2 | Дайджесты недели | 2-й |
| 3+4 | Подборки сервисов + AI/tool обзоры | 3-й |
| 1 | Новостные посты (RSS-рерайт) | 4-й |

См. `docs/types-roadmap.md` для деталей каждого.

**MVP = Vacancy-pipeline.** Input — текст вакансии. Output — папка-bundle:

```
post_bundles/vacancy_2026-05-11_<slug>_<hash>/
├── bundle.json
├── tg.md                ← готовый caption для Telegram (HTML, ~600-1000 chars)
├── hashtags-tg.txt      ← #вакансия #арбитраж ...
├── slide_01.png         ← Hook (company + position + salary)
├── slide_02.png         ← Requirements
├── slide_03.png         ← Tasks
├── slide_04.png         ← Benefits
└── slide_05.png         ← Apply (CTA + contact)
```

SMM-щик в v1 берёт папку, в TG-клиенте грузит slides + paste caption → пост. **Публикация автоматизируется в v2** — спеки в `docs/v2-publication/`.

**Instagram — отдельный трек позже.** В v1 фокус только на TG.

## Что переиспользуем из существующего SMM

| Класс | Где | Как используем |
|---|---|---|
| `TopicResearcher` | `research/` | Same — fetch `traffnews.com`, web_search для контекста |
| `DirectorAgent` (или новый `PostDirector`) | `director/` | Аналог: gpt-4o → JSON brief с caption'ами и slide tezisи |
| `ImagePromptBuilder` | `director/` | Reuse для генерации image prompts per slide |
| Brand DNA (цвета, шрифты) | константы | Same — blue-deep + yellow + Manrope/Russo One/JetBrains Mono |
| HF templates (если применимо) | `external/hyperframes-student-kit/` | Templates для slide-карточек |

## Что НЕ нужно для статики

- ElevenLabs TTS (нет аудио)
- Hedra avatar (хотя можно подмешать для hero-slide в v2)
- AssGenerator burn-in (нет видео-субтитров)
- BrandedFinisherHF video composition (нет видео-склейки)
- Render QA для видео (заменяется PostQA для статики)

## Документация

**MVP-focused (читать первым):**
- [`docs/mvp-vacancies.md`](./docs/mvp-vacancies.md) — спека первого пайплайна (вакансии)
- [`docs/types-roadmap.md`](./docs/types-roadmap.md) — все 5 типов от Дарии и очерёдность

**Framework (общая для всех типов):**
- [`docs/post-pipeline.md`](./docs/post-pipeline.md) — обобщённый flow (input → research → director → slides → bundle). Каждый тип = специализация этого framework.
- [`docs/bundle-spec.md`](./docs/bundle-spec.md) — формат bundle (JSON schema, file naming) — применим ко всем типам
- [`docs/integration-plan.md`](./docs/integration-plan.md) — куда в `D:\Prog\SMM` идёт код, какие классы reuse

Reference:
- `D:\Prog\SMM\CLAUDE.md` — read first (HARD RULES, brand voice, fabrication policy, phonetic anglicisms)
- `D:\Prog\SMM\docs\` — детали существующего видео-pipeline

V2 (отложено):
- [`docs/v2-publication/`](./docs/v2-publication/) — спеки автопубликации в TG/IG (Bot API + Graph API + Dashboard `/social` page)

Notion: https://www.notion.so/35dde7a6942a81e1a731e9bb58edb73c

## Старт работы

Открыть [`CLAUDE.md`](./CLAUDE.md).
