# Type 2 — Weekly Digest

Дайджест главных новостей за неделю → один TG-пост (текст + опционально 1-2 слайда обложки).

**Статус:** 🟦 stub. Заполнить когда Vacancy MVP стабилен.

## Источник данных

**RSS:** `https://traffnews.com/category/news/feed/` ← **верифицировано 2026-05-11**

- RSS 2.0
- 10 последних статей в фиде
- Все нужные поля: `title`, `link`, `description`, `pubDate`, `content:encoded`, `guid`
- На сайте 40 страниц истории в категории — для самого дайджеста хватает свежих 10 из фида

**Преимущества vs альтернатив:**
- ✅ Просто RSS-poll, никакого Telegram Bot API hacks
- ✅ Все статьи уже категоризированы (`/category/news/`) — никакой фильтр-логики
- ✅ История доступна (40 страниц, можно догнать прошлое если нужно)
- ❌ Никаких

## Триггер

- **Cron:** каждую пятницу 16:00 МСК (или другой день — согласовать с Дарией)
- Опция: manual trigger из CLI / Dashboard для ad-hoc запуска

## Pipeline

```
cron Friday 16:00 МСК
       ↓
DigestCollector
  - GET https://traffnews.com/category/news/feed/
  - filter: items where pubDate >= (now - 7 days)
  - extract { title, link, summary (from description), pubDate, cover (from content_html) }
       ↓
[if items.count < 3 → skip this week]
       ↓
DigestDirector (gpt-4o)
  prompt: "Сделай дайджест за неделю из N новостей. Один пост, 5-7 главных с короткими summary.
           Тон: информативный, минималистичный. Каждая строка ≤ 80 chars.
           Anti-fabrication: не добавляй фактов которых нет в исходниках."
  output: DigestBrief {
    week_label:      "5-11 мая 2026",
    intro:           "Главное за неделю в арбитраже:",
    items: [
      { idx: 1, title: "...", summary: "...", link: "..." },
      ...
    ],
    cta:             "Полные разборы — на traffnews.com"
  }
       ↓
SlideExecutor (optional, 1-2 slides)
  - slide_01: Cover ("Дайджест недели · 5-11 мая 2026", brand frame)
  - slide_02: Numbered list 5-7 пунктов (если карусель нужна)
       ↓
BundleAssembler → digest_2026-W19_<hash>/
```

## Caption формат

```html
🗞 <b>Дайджест недели</b>
{week_label}

1. <b>{item_1.title}</b>
   {item_1.summary_short}

2. <b>{item_2.title}</b>
   {item_2.summary_short}

3. <b>{item_3.title}</b>
   {item_3.summary_short}

4. <b>{item_4.title}</b>
   {item_4.summary_short}

5. <b>{item_5.title}</b>
   {item_5.summary_short}

Все материалы недели — traffnews.com/category/news/

#дайджест
```

Длина 800-1500 символов. Без медиа (текстовый пост `sendMessage`) или с обложкой (`sendPhoto`).

**Ссылки на каждый item** — НЕ в основном посте (TG не любит много ссылок и preview-карточек). Варианты:
- Опубликовать пост → в **первом комментарии** к нему: список ссылок «1. {item_1.link} ...»
- Или: каждый item linkified прямо в caption через `<a href>` (TG разрешает, но визуально кашеобразно при 5+ ссылок)

## Slides (опционально для MVP)

- **slide_01** — Cover: «Дайджест недели · {week_label}», brand frame, можно с emoji 🗞
- **slide_02** — Numbered list 5-7 заголовков, без summary (summary в caption)

Для MVP — **посты без слайдов**, чисто текстовые. Слайды добавим если SMM запросит.

## Bundle

```
post_bundles/digest_2026-W19_<hash>/
├── bundle.json (post_type: "digest")
├── tg.md
├── hashtags-tg.txt              (#дайджест)
├── items.json                   (debug: что DigestCollector собрал)
├── brief.json                   (debug: что DigestDirector вернул)
└── slide_01.png                 (опционально)
```

## Bundle.json особенности

```json
{
  "post_type": "digest",
  "topic": "Дайджест недели · 5-11 мая 2026",
  "week_iso": "2026-W19",
  "items_count": 5,
  "source_links": [
    "https://traffnews.com/news/...",
    "https://traffnews.com/news/...",
    ...
  ]
}
```

## Anti-fabrication для digest

- Каждый summary — **переформулированный** description из RSS, не выдумка
- Числа / имена / даты — verbatim из исходной статьи
- Никаких «связок» («это значит что Y» если в источнике нет вывода)
- Если в week-window < 3 статей — **не публиковать дайджест**, sk ip неделю (лучше пропустить чем выдавать дайджест из 1-2 пунктов)

## Visual tone

- Informational, neutral
- Минимум эмодзи (одного 🗞 в hook достаточно)
- Numbered list emphasis
- Brand-frame minimal (если делать slide)

## Открытые вопросы

1. **День публикации** — пятница 16:00 МСК? Или Дария предпочитает другой день?
2. **Количество items** — 5-7 фиксировано или зависит от того что есть?
3. **Slides** — нужны на MVP или текстовый пост достаточен?
4. **Минимальный порог** — если за неделю было 1-2 новости, skip или сделать дайджест с тем что есть?

## Зависимости

- RSS-фид `traffnews.com/category/news/feed/` (стабильно работает — на WordPress по умолчанию)
- `BaseDirector` reuse
- (Если со слайдами) `Java2DSlideRenderer` для cover-template
