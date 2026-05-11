# Bundle Spec

Точный формат выходного post-bundle. Bundle = одна папка со всем нужным для публикации одного поста (TG + IG версии под одним общим брифом).

## Directory layout

```
post_bundles/
└── 2026-05-11_rutub-payouts_a7f3c2/        ← bundle root
    ├── bundle.json                          ← metadata (см. ниже)
    ├── tg.md                                ← готовый caption для Telegram (HTML)
    ├── ig.md                                ← готовый caption для Instagram (plain)
    ├── hashtags-tg.txt                      ← #полезное (один навигационный)
    ├── hashtags-ig.txt                      ← #арбитраж #cpa ... (15-25 тегов)
    ├── slide_01.png                         ← карусель-карточка #1
    ├── slide_02.png
    ├── slide_03.png
    ├── slide_04.png
    ├── slide_05.png
    ├── slide_06.png
    ├── slide_07.png
    ├── research.json                        ← debug: что Researcher собрал
    ├── post_brief.json                      ← debug: что Director вернул
    └── qa_report.json                       ← debug: PostQA результаты
```

## Naming convention bundle-папки

```
<YYYY-MM-DD>_<topic-slug>_<hash>
```

- **YYYY-MM-DD** — дата генерации, не дата публикации (публикация может откладываться)
- **topic-slug** — kebab-case slug из топика, ASCII, ≤30 chars. Сгенерить через `Slugify(topic).toAscii().toLowerCase()`. Пример: `rutub-payouts`, `crash-casino-2026`, `vavada-eu-launch`
- **hash** — 6-символьный hex от `sha256(topic + timestamp)` для уникальности (избежать коллизий если 2 поста с одинаковым slug в один день)

Пример: `2026-05-11_rutub-payouts_a7f3c2`

## `bundle.json` schema

```json
{
  "version": 1,
  "id": "2026-05-11_rutub-payouts_a7f3c2",
  "topic": "Сколько платит Рутуб в 2026",
  "source": {
    "url": "https://traffnews.com/uncategorized/skolko-platit-rutub/",
    "title": "Сколько платит Рутуб в 2026: реальные цифры, формулы и как зарабатывать на просмотрах",
    "published_at": "2026-05-11T09:00:00Z",
    "author": "TraffNews"
  },
  "generated_at": "2026-05-11T15:42:18Z",
  "generator": {
    "version": "post-pipeline-0.1.0",
    "director_model": "gpt-4o-2026-03-15",
    "image_renderer": "recraft-v3"
  },
  "world": "Studio Anchor",
  "tone": "educational",
  "slide_count": 7,
  "slides": [
    {
      "idx": 1,
      "role": "hook",
      "file": "slide_01.png",
      "visual_intent": "big_number",
      "text": "Сколько платит Рутуб?",
      "qa_status": "pass"
    },
    {
      "idx": 2,
      "role": "fact",
      "file": "slide_02.png",
      "visual_intent": "big_number",
      "text": "50-120 ₽ за 1000 просмотров",
      "qa_status": "pass"
    },
    ...
  ],
  "status": "ready_for_review",
  "qa": {
    "vision_pass_rate": "7/7",
    "text_legibility": "pass",
    "brand_dna_preserved": "pass",
    "eyes_check_done": false,
    "fabrication_check": "pass",
    "phonetic_anglicism_check": "pass"
  },
  "publication": {
    "tg": { "posted": false, "message_id": null, "posted_at": null },
    "ig": { "posted": false, "media_id": null, "posted_at": null }
  }
}
```

## `status` enum

Жизненный цикл bundle:

| status | Описание | Можно публиковать? |
|---|---|---|
| `generating` | Pipeline в процессе | ❌ |
| `qa_failed` | PostQA нашёл проблему | ❌ |
| `ready_for_review` | Pipeline закончил, ждём eyes-check | ⚠️ можно но без eyes-check рисково |
| `approved` | SMM поставил approval (manual) | ✅ |
| `posted_partial` | Опубликовано в одну платформу, вторая упала | ⚠️ |
| `posted` | Опубликовано во все выбранные платформы | ✅ done |
| `archived` | Старше 30 дней, перенесено | ✅ historical |

В v1 (без Dashboard) `status` обновляется руками — SMM редактирует `bundle.json` или через CLI.

В v2 (с Dashboard) — UI кнопки `[Approve]` `[Reject]` `[Mark posted]` обновляют `status`.

## `tg.md` content

Точный текст для копирования в Telegram. **HTML-formatted**, готов к `sendMessage` / `sendPhoto` с `parse_mode=HTML`.

Пример:
```html
💸 <b>Сколько платит Рутуб в 2026</b>

Реальные цифры от площадки:

• RPM 50-120 ₽ за 1000 просмотров
• Выплаты раз в месяц после порога 10 000 ₽
• Топ-каналы получают до 1 млн ₽/мес

Если ты лил трафик на видео-офферы — это твой второй источник дохода.

Полный разбор с формулами 👉 <a href="https://traffnews.com/uncategorized/skolko-platit-rutub/">читай на TRAFFNEWS</a>

#полезное
```

Конец файла = пустая строка + хэштег. Один навигационный хэштег (`#полезное` / `#новости` / `#мероприятия` / `#розыгрыш`).

## `ig.md` content

Plain text + emoji. **Никакого HTML** — IG не парсит. Ссылки **не кликабельны** в caption → не вставлять полные URL в тело, упоминать `traffnews.com` (можно goo.gl-ссылку, но лучше "ссылка в шапке профиля").

Пример:
```
💸 Сколько платит Рутуб в 2026

Реальные цифры от площадки:

• RPM 50-120 ₽ за 1000 просмотров
• Выплаты раз в месяц после порога 10 000 ₽
• Топ-каналы получают до 1 млн ₽/мес

Если ты лил трафик на видео-офферы — это твой второй источник дохода.

Полный разбор с формулами — ссылка в шапке профиля ☝️
```

Хэштеги — отдельным файлом `hashtags-ig.txt`, чтобы IG-клиент мог брать их **из первого комментария** (best practice для discoverability — не засорять основной caption).

## `hashtags-ig.txt` content

15-25 хэштегов, одна строка, через пробел:

```
#арбитражтрафика #cpa #affiliate #affiliatemarketing #партнёрки #вебмастер #арбитраж #рутуб #монетизация #видеомаркетинг #ютуб #контентмейкинг #digital #performance #cpa_network #performance_marketing #трафик #пассивныйдоход #онлайнзаработок #инфобизнес
```

## `hashtags-tg.txt` content

Одна строка, один тег:

```
#полезное
```

## Slide image specifications

| Параметр | Значение |
|---|---|
| Format | PNG (lossless для brand consistency) |
| Размер | **1080×1350** (IG carousel ratio 4:5) |
| Color profile | sRGB |
| Bit depth | 8-bit |
| Compression | PNG-optimised, ≤2 MB per slide (для быстрой загрузки в IG) |
| Naming | `slide_NN.png` где NN — zero-padded двузначное число (01, 02, ..., 10) |

Telegram примет такой же 1080×1350 — у TG нет строгих ratio. **Один и тот же файл слайда подходит и для IG, и для TG carousel.** Никакого ресайза.

## Validation rules для bundle

Прежде чем `status: ready_for_review` — pipeline проверяет:

```pseudo
function validateBundle(dir):
  assert exists bundle.json (parseable JSON)
  assert bundle.slide_count == count(slide_*.png in dir)
  assert bundle.slide_count in 5..10
  assert exists tg.md, len(content) > 100 and len(content) <= 4096
  assert exists ig.md, len(content) > 100 and len(content) <= 2200
  assert exists hashtags-tg.txt, contains exactly 1 hashtag from whitelist
  assert exists hashtags-ig.txt, contains 10..30 hashtags
  for slide in slides:
    assert exists file matching slide.file
    assert dimensions == 1080x1350
    assert size <= 2_000_000  // 2MB
  assert bundle.qa.fabrication_check == "pass"
  assert bundle.qa.phonetic_anglicism_check == "pass"
```

Если что-то fail — `status: qa_failed`, `qa.error` заполнен. SMM может посмотреть детали, поправить вручную (если мелочь) или перегенерить.

## Bundle storage path

В development: `D:\Prog\SMM\post_bundles\`
В production (когда подключим Dashboard): Supabase Storage bucket `post-bundles`, путь `<bundle-id>/...`

`.gitignore` корня D:\Prog\SMM\ должен включать `post_bundles/` — это generated output, не source.

## Bundle as deliverable

Bundle — это атомарная единица передачи. Можно:
- Zip → отправить SMM в Telegram
- Загрузить на Google Drive целиком
- Скопировать на флешку
- В v2 — Dashboard читает bundle и публикует через TG/IG API

Каждый bundle self-contained — не зависит от внешних URL для самого контента (slide PNG в самом bundle).
