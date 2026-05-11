# Traffnews Posting — Fresh Agent Entry Point

## ⚠️ Сначала прочитай это

**Эта папка (`D:\Prog\Постинг\`) — только спецификации.** Код пишется в **`D:\Prog\SMM\`** как расширение существующего проекта SOCL-04 (видео-pipeline).

Перед написанием любого Java-кода — **обязательно прочитать `D:\Prog\SMM\CLAUDE.md`**. Там HARD RULES уровня всей кодовой базы: brand voice, anti-fabrication, phonetic anglicisms, темы только с traffnews.com, Java-only для нового кода, и т.д. Все эти правила **применимы и к нашему post-pipeline** — мы не отдельный проект, мы вторая ветка.

## Что это в одном абзаце

Параллельная ветка к существующему video pipeline (SOCL-04). Тот же brand voice, та же DirectorAgent-логика, тот же `TopicResearcher` — но **на выходе не видео, а bundle-папка** со статическим контентом: `tg.md` + `slide_01..NN.png`. Только Telegram в v1 (IG — отдельный трек позже). Bundle потребляется SMM-щиком вручную (в v1 — копирует в TG руками; в v2 — Dashboard `/social` страница с кнопкой Publish).

**5 типов постов** (от Дарии, SMM-щика): Вакансии (MVP), Дайджесты недели, Подборки сервисов, Tool обзоры, Новостные посты. Каждый = свой подпайплайн со своим Extractor + Director. Backbone (BaseDirector, SlideRenderer, BundleWriter) — общий.

См. `docs/types-roadmap.md` и `docs/mvp-vacancies.md`.

## Архитектура

```
INPUT
  └── traffnews.com URL  ИЛИ  topic-prompt
            ↓
TopicResearcher (reuse from D:\Prog\SMM\research\)
  └── fetch article + web_search → research.json
            ↓
PostDirector (NEW, analog DirectorAgent)
  └── gpt-4o → post_brief.json:
       {
         tg_caption:  "...",   // HTML-формат, 5-block (HOOK/CONTEXT/STAKES/MECHANICS/CTA адаптирован для текста)
         ig_caption:  "...",   // plain, чуть длиннее, без ссылок
         tg_hashtag:  "#полезное",
         ig_hashtags: "#арбитраж #cpa ...",  // 15-25 тегов
         slides: [
           { idx: 1, text: "...", visual_intent: "big_number alarm", image_prompt: "..." },
           { idx: 2, text: "...", visual_intent: "text_card", image_prompt: "..." },
           ...
         ]
       }
            ↓
[VIEWER-WALKTHROUGH — mental pass, как в видео-pipeline]
            ↓
PostSlideExecutor (NEW)
  └── для каждого slide → render PNG 1080×1350 (IG carousel-friendly)
       brand DNA: blue-deep + yellow, Manrope/Russo One/JetBrains Mono
       reuse ImagePromptBuilder, vision-verify
            ↓
PostBundleAssembler (NEW)
  └── собирает bundle folder:
       post_bundles/2026-05-11_topic-slug_HASH/
         ├── bundle.json
         ├── tg.md / ig.md / hashtags-*.txt
         └── slide_01.png ... slide_07.png
            ↓
PostQA (NEW, analog RenderQA)
  └── vision-check: slides match topic, brand DNA preserved, text legibility OK
            ↓
OUTPUT
  └── ready bundle → SMM picks up manually
```

## HARD RULES — что применимо из SMM CLAUDE.md к нашему пайплайну

1. **Темы — только traffnews.com.** Не выдумывать generic SMM-темы. Workflow: traffnews.com → 1-2 кандидата → fetch → research.
2. **Только русский в captions.** Phonetic anglicisms: `Гугл{Google}`, `Фейсбук{Facebook}`. TTS не нужен (нет аудио), но в IG/TG-caption то же правило для читабельности — англиц лет на 30, кириллица читается мгновенно.
3. **NO fabricated facts.** Каждое утверждение в caption — прямо из источника. Числа — реальные. Никаких выдуманных ROI / реакций регуляторов.
4. **5-block structure (адаптировано для текста):**
   - **HOOK** — первая строка, эмодзи + контроверсия / число / опасность / возможность
   - **CONTEXT** — 1-2 строки, что произошло, факты
   - **STAKES** — почему важно арбитражнику (удар по кошельку / трафику)
   - **MECHANICS** — 2-3 actionable шага с цифрами
   - **CTA** — «Подробный разбор на traffnews.com → [link]»
5. **Per-sentence clarity-check.** Те же 7 правил (длина ≤18 слов, без канцелярита, числа с единицами, ...) применяются к caption'ам.
6. **Verify-or-reject для assets.** Если slide image не отрендерился / brand_logo не найден — REJECT shot, не silent fallback.
7. **Eyes-check после рендера.** Vision-API проверяет intent, но финально — человеческий взгляд на bundle перед «готово».

## Что НЕ применимо (что отличает нас от видео)

- ❌ ElevenLabs TTS (нет аудио в bundle)
- ❌ Hedra avatar (карусель-карточки не avatar-портреты, хотя hero-slide с avatar — идея для v3)
- ❌ AssGenerator burn-in (нет видео-субтитров)
- ❌ Caption-zone y>1440 (это про видео; для static 1080×1350 свои inviolable zones — см. `docs/post-pipeline.md`)
- ❌ shot_list с таймкодами (slides не по таймлайну, они независимы)

## Где живёт что

| Артефакт | Где |
|---|---|
| Java-код нового pipeline | `D:\Prog\SMM\scripts\java\src\main\java\com\traffnews\smm\post\` |
| Тесты | `D:\Prog\SMM\scripts\java\src\test\java\com\traffnews\smm\post\` |
| Bundle-output (генерируемые posts) | `D:\Prog\SMM\post_bundles\<timestamp>_<slug>_<hash>\` (gitignored) |
| Спецификации | `D:\Prog\Постинг\docs\*.md` |
| Future publication spec | `D:\Prog\Постинг\docs\v2-publication\*.md` |
| Hard rules common to all SMM | `D:\Prog\SMM\CLAUDE.md` (НЕ дублировать здесь) |

## Какой файл открывать под какую задачу

| Задача | Открывай |
|---|---|
| Понять flow от input до bundle | `docs/post-pipeline.md` |
| Узнать точный формат bundle / file naming | `docs/bundle-spec.md` |
| Что добавляется в SMM Java, что переиспользуется | `docs/integration-plan.md` |
| Brand voice / fabrication policy / phonetic anglicisms | `D:\Prog\SMM\CLAUDE.md` (источник правды) |
| Спека публикации (v2) | `docs/v2-publication/` |

## Do / Don't

✅ Делать:
- Новый код — Java, package `com.traffnews.smm.post.*`
- Переиспользовать `TopicResearcher`, `ImagePromptBuilder`, brand DNA из существующего SMM
- Bundle = self-contained папка (можно перенести / архивировать / отправить)
- Все captions через clarity-check (per-sentence, 7 правил)
- Анализ источника = traffnews.com article, не выдумка
- Vision-verify каждого slide до маркировки bundle как ready

❌ Не делать:
- Python-код для нового pipeline (Java-only convention)
- Дублировать HARD RULES из `D:\Prog\SMM\CLAUDE.md` сюда (single source of truth)
- Bundle с partial output (если 3 из 7 slides упали — bundle = failed, не shippable)
- Публикацию в TG/IG в v1 (это v2, см. `docs/v2-publication/`)
- Прямой anthropic/openai API ключи (использовать существующий `.env` SMM-проекта)
