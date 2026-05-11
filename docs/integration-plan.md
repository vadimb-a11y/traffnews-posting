# Integration Plan

Что и куда добавляется в `D:\Prog\SMM` чтобы поднять post-pipeline. **Не отдельный проект** — расширение существующего.

## Целевая структура SMM после интеграции

```
D:\Prog\SMM\
├── CLAUDE.md                                          (существующий, не трогаем)
├── .env                                                (существующий, добавим IG/TG keys в v2)
├── docs/                                               (существующие doc'и видео-pipeline)
│   ├── PRE-DELIVERY-CHECKLIST.md
│   ├── director-playbook.md
│   ├── ...
│   └── post-pipeline-checklist.md                      ← НОВЫЙ: чек-лист A→F для post-bundle
├── scripts/java/
│   ├── pom.xml                                          (existing, добавим depend если надо)
│   ├── src/main/java/com/traffnews/smm/
│   │   ├── research/                                    (existing — TopicResearcher)
│   │   │   └── TopicResearcher.java                     (reuse as-is)
│   │   ├── director/                                    (existing)
│   │   │   ├── DirectorAgent.java                       (video; reuse common, refactor as base)
│   │   │   ├── ImagePromptBuilder.java                  (reuse as-is)
│   │   │   └── BaseDirector.java                        ← НОВЫЙ (extract common из DirectorAgent)
│   │   ├── executor/                                    (existing — ShotExecutor, video-specific)
│   │   ├── finisher/                                    (existing — BrandedFinisherHF)
│   │   ├── hedra/                                       (existing, не нужно для post)
│   │   ├── elevenlabs/                                  (existing, не нужно для post)
│   │   ├── ass/                                         (existing, не нужно для post)
│   │   └── post/                                        ← НОВЫЙ ПАКЕТ для post-pipeline
│   │       ├── PostPipelineRunner.java                  ← entry point (main / CLI / scheduled)
│   │       ├── PostDirector.java                        ← gpt-4o → post_brief.json
│   │       ├── PostSlideExecutor.java                   ← render 1080×1350 PNG
│   │       ├── PostBundleAssembler.java                 ← собирает bundle/ folder
│   │       ├── PostQA.java                              ← vision-check + validation
│   │       ├── model/
│   │       │   ├── PostBrief.java                       ← POJO для post_brief.json
│   │       │   ├── Slide.java                           ← POJO одного слайда
│   │       │   ├── Bundle.java                          ← POJO для bundle.json
│   │       │   └── PostStatus.java                      ← enum
│   │       ├── render/
│   │       │   ├── SlideRenderer.java                   ← interface
│   │       │   ├── Java2DSlideRenderer.java             ← опция A: чистый Java2D
│   │       │   ├── HfTemplateSlideRenderer.java         ← опция B: HF templates
│   │       │   └── RecraftSlideRenderer.java            ← опция C: Recraft v3 via Replicate
│   │       └── output/
│   │           └── BundleWriter.java                    ← создаёт папку, пишет файлы
│   └── src/test/java/com/traffnews/smm/post/
│       ├── PostDirectorTest.java
│       ├── PostBundleAssemblerTest.java
│       ├── PostQATest.java
│       └── fixtures/
│           └── research_rutub.json
├── tests/                                              (existing bundles для видео — не трогаем)
└── post_bundles/                                       ← НОВЫЙ output (gitignored)
    └── <date>_<slug>_<hash>/
        └── ...
```

## Что добавляется

### Новые Java-классы (`com.traffnews.smm.post.*`)

- **`PostPipelineRunner`** — main(). Принимает `--source-url` или `--topic`, оркестрирует pipeline, пишет bundle. CLI entry-point для дев-теста; позже вызывается из dashboard / cron.
- **`PostDirector`** — gpt-4o клиент, строит prompt с правилами (5-block structure, no fabrication, phonetic anglicisms), парсит response → `PostBrief` POJO.
- **`PostSlideExecutor`** — итерируется по `brief.slides`, для каждого вызывает `SlideRenderer.render(slide)`, сохраняет PNG, vision-verify.
- **`PostBundleAssembler`** — собирает финальный bundle: создаёт папку, пишет tg.md / ig.md / hashtags-*.txt / bundle.json, копирует/перемещает PNG, аккуратно складирует debug-артефакты (`research.json`, `post_brief.json`, `qa_report.json`).
- **`PostQA`** — vision-check каждого слайда (gpt-4o-mini), text legibility (опционально OCR на собственном выводе для read-back), fabrication-check на caption'ах против research.json, phonetic-anglicism-check regex.

### Новые POJOs (`com.traffnews.smm.post.model.*`)

- **`PostBrief`** — JSON-маппинг output'а PostDirector
- **`Slide`** — один slide (idx, role, text, visual_intent, image_prompt, image_path, qa_status)
- **`Bundle`** — JSON-маппинг bundle.json (см. `docs/bundle-spec.md`)
- **`PostStatus`** — enum: GENERATING, QA_FAILED, READY_FOR_REVIEW, APPROVED, POSTED_PARTIAL, POSTED, ARCHIVED

### Slide renderer — выбор реализации

`SlideRenderer` — интерфейс. Три implementations, выбор через env / config:

#### A. `Java2DSlideRenderer` — чистый Java2D / Skija
- **Плюс:** brand DNA контролируется идеально (точные цвета, шрифты, отступы). Кириллица рендерится надёжно. Text fidelity 100%.
- **Минус:** нужно сделать template'ы для каждого `visual_intent` (big_number, text_card numbered, ...). Это 1-2 дня работы.
- **Когда выбирать:** для production. Самый предсказуемый рендерер.

#### B. `HfTemplateSlideRenderer` — HyperFrames templates
- **Плюс:** если уже есть HF templates под brand, reuse. Composition богаче чем чистый Java2D.
- **Минус:** зависит от `external/hyperframes-student-kit/`, нужно изучить existing templates на пригодность.
- **Когда выбирать:** если HF templates легко подкручиваются под slide-формат.

#### C. `RecraftSlideRenderer` — Recraft v3 via Replicate
- **Плюс:** красивые brand-friendly иллюстрации с правильным текстом на изображении (Recraft v3 — best для on-screen text).
- **Минус:** $0.04/image × 7 slides = $0.28/bundle. На 30 постов/мес = $8/мес. Не критично, но кэш не работает (каждый раз новая ген.). И text fidelity не 100% — может всё-таки сгенерить опечатку.
- **Когда выбирать:** для hero/cover slide, не для list-карточек.

**MVP — начать с A (Java2D).** Самое предсказуемое для брендовых шаблонов. Добавить C опцию позже для разнообразия.

### Изменения в существующих классах

- **`DirectorAgent`** → extract common часть в новый `BaseDirector` (abstract class):
  - Promptbuilding skeleton
  - gpt-4o client wrapping
  - retry / parsing
- `DirectorAgent extends BaseDirector` — video-specific
- `PostDirector extends BaseDirector` — post-specific

Это refactor существующего кода. Аккуратно — нужно прогнать всё видео-pipeline после рефакторинга чтобы убедиться что ничего не сломалось.

Альтернатива: не рефакторить, скопировать паттерн. Менее DRY но безопаснее.

## Зависимости (pom.xml дополнения)

Большинство есть, но проверить:

| Зависимость | Зачем | Likely already in pom |
|---|---|---|
| `com.fasterxml.jackson.core:jackson-databind` | JSON (POJO ↔ JSON) | Yes (DirectorAgent uses) |
| `org.openai:openai-java` или OkHttp + manual | OpenAI API client | Yes (DirectorAgent uses) |
| `com.github.slugify:slugify` | topic-slug generation | Add if absent |
| (для Java2D) `nothing new` | JDK built-in | — |
| (для Skija) `io.github.humbleui:skija-windows-x64` | Если выбираем Skija вместо Java2D | Add if needed |
| (для Recraft option) `replicate-java-sdk` | API client | Add if option C активируется |

## Env variables (`.env` SMM)

Добавляются (в `.env`, plaintext, не коммитить):

```
# Existing (для video pipeline):
OPENAI_API_KEY=sk-...           # переиспользуем для post-pipeline
ELEVENLABS_API_KEY=...          # не нужен для post
HEDRA_API_KEY=...               # не нужен для post

# New (для post-pipeline):
REPLICATE_API_TOKEN=r8_...      # если используется RecraftSlideRenderer
POST_BUNDLE_DIR=./post_bundles  # output путь (default = ./post_bundles)
POST_SLIDE_RENDERER=java2d      # java2d | hf | recraft (выбор реализации)

# v2 (для публикации):
# TELEGRAM_BOT_TOKEN=...
# TELEGRAM_CHANNEL_ID=@traffnews
# INSTAGRAM_ACCESS_TOKEN=...
# INSTAGRAM_BUSINESS_ACCOUNT_ID=...
```

## CLI usage (MVP)

```powershell
cd D:\Prog\SMM
mvn -pl scripts/java compile

# Generate bundle from article URL
java -cp scripts/java/target/classes com.traffnews.smm.post.PostPipelineRunner `
  --source-url "https://traffnews.com/uncategorized/skolko-platit-rutub/" `
  --output-dir ./post_bundles

# Or from topic prompt (no specific article)
java -cp scripts/java/target/classes com.traffnews.smm.post.PostPipelineRunner `
  --topic "новые правила Google Ads для гемблинга в мае 2026" `
  --output-dir ./post_bundles
```

Output:
```
✓ Researcher fetched 3 sources
✓ PostDirector generated brief (world=Studio Anchor, tone=educational, 7 slides)
✓ Clarity-check: 12/12 sentences PASS
✓ Viewer-walkthrough: 7/7 slides tone-consistent
✓ PostSlideExecutor rendered 7/7 slides
✓ PostQA: vision-pass 7/7, fabrication=pass, anglicism=pass
✓ Bundle ready: ./post_bundles/2026-05-11_rutub-payouts_a7f3c2/
   - tg.md (847 chars)
   - ig.md (1342 chars)
   - 7 slides
   status: ready_for_review
```

## Migration plan / phases

### Phase 0 — спецификации (то что я делаю сейчас)
- Doc'и в `D:\Prog\Постинг\docs\` (этот файл, post-pipeline.md, bundle-spec.md)
- Создание Notion-страницы (уже есть)

### Phase 1 — backbone (1-2 дня)
- Создать пакет `com.traffnews.smm.post.*`
- POJOs (`PostBrief`, `Slide`, `Bundle`, `PostStatus`)
- Скелет `PostPipelineRunner` с CLI args
- Wire up `TopicResearcher` reuse
- `PostDirector` с минимальным prompt'ом, returns dummy `PostBrief`
- `BundleWriter` пишет tg.md / ig.md / bundle.json (без slides)
- Test: end-to-end на dummy data, bundle папка появляется

### Phase 2 — text generation quality (2-3 дня)
- Полный prompt в `PostDirector` со всеми правилами (5-block, anti-fabrication, anglicisms)
- Clarity-check автоматизированный (если возможно) или manual
- Viewer-walkthrough как mental pass с эвристиками
- Тесты на 3-5 разных traffnews-статьях
- Iterate на промпте до качества «не стыдно показать»

### Phase 3 — slide rendering (3-5 дней)
- `Java2DSlideRenderer` — каркас + templates для основных visual_intent типов
- Brand DNA constants (цвета, шрифты, отступы)
- Vision-verify per slide
- Тесты: рендер каждого visual_intent

### Phase 4 — QA + integration (1-2 дня)
- `PostQA` — все check'ы (vision, fabrication, anglicism, text-legibility)
- `qa_report.json` artifact
- Integration test: реальная статья → bundle → manual eyes-check

### Phase 5 — manual usage (открыт)
- SMM пробует постить bundles вручную
- Feedback loop → улучшения промпта / templates / brand DNA
- 2-4 недели live-use

### Phase 6 — publication (v2, см. `docs/v2-publication/`)
- Когда генерация стабильна — поднимать `/social` page в Dashboard
- TG/IG API интеграция
- Bundle storage в Supabase

## Конвенции из `D:\Prog\SMM\CLAUDE.md`, обязательные для post-кода

Дублирую критичные (полностью — там):

- ⚠️ **Только Java для нового кода**
- ⚠️ **Комментарии — на русском**
- ⚠️ **API-ключи только в `.env`**, не коммитить
- ⚠️ **Темы только с traffnews.com**
- ⚠️ **NO fabricated facts** — каждое утверждение из источника
- ⚠️ **Phonetic anglicisms** `Гугл{Google}` в caption'ах (хотя для текста менее критично чем для TTS)
- ⚠️ **Verify-or-reject** для assets (slide image не отрендерился → REJECT, не silent fallback)
- ⚠️ **Per-sentence clarity-check** для caption'ов
- ⚠️ **Eyes-check** после рендера (даже при 10/10 QA)
- ⚠️ **CLAUDE.md discipline** — при добавлении post-кода обновить `D:\Prog\SMM\CLAUDE.md` секцией про post-pipeline (или ссылкой на `D:\Prog\Постинг\CLAUDE.md`)

## Что должен сделать разработчик в первый день

1. Прочитать `D:\Prog\SMM\CLAUDE.md` целиком (это HARD RULES)
2. Прочитать `D:\Prog\Постинг\README.md` + `CLAUDE.md` (это контекст ветки)
3. Прочитать все 3 файла `D:\Prog\Постинг\docs\*.md`
4. Сделать `mvn compile` существующего проекта — убедиться что build работает
5. Создать пустой пакет `com.traffnews.smm.post`
6. Скелет `PostPipelineRunner` с `--help` и парсингом args
7. Прогнать пустой PostPipelineRunner — должен напечатать args и завершиться
8. Только после этого — начинать `PostDirector`
