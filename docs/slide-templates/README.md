# Slide Templates for APITemplate.io

Готовые HTML-шаблоны под копипаст в APITemplate.io UI. Каждый файл соответствует одному `visual_intent` из 9.

## Как использовать

1. Открыть APITemplate.io → **+ New Template** → **HTML to Image**
2. Размер: **1080 × 1350**
3. Открыть нужный файл здесь
4. Скопировать **содержимое `<style>`** → вкладка **CSS** в APITemplate
5. Скопировать **содержимое `<body>`** (только то что внутри `<body>...</body>`) → вкладка **HTML** в APITemplate
6. На вкладке **Sample Data** вставить тестовый JSON из header-комментария файла
7. **Save** → запомнить **Template ID**
8. Test render в их preview-панели → сверить с `preview/slide-02-hybrid-v2.png` или соответствующим референсом

## Список шаблонов (статус)

| # | visual_intent | Файл | Статус |
|---|---|---|---|
| 1 | cover | `slide-01-cover.html` | 🟡 TODO |
| 2 | big_number | `slide-02-big-number.html` | ✅ Готов |
| 3 | quote_block | `slide-03-quote.html` | 🟡 TODO |
| 4 | bullet_list | `slide-04-bullet-list.html` | 🟡 TODO |
| 5 | numbered_list | `slide-05-numbered-list.html` | 🟡 TODO |
| 6 | service_list | `slide-06-service-list.html` | 🟡 TODO |
| 7 | compare_split | `slide-07-compare.html` | 🟡 TODO |
| 8 | faq | `slide-08-faq.html` | 🟡 TODO |
| 9 | outro_cta | `slide-09-outro.html` | 🟡 TODO |

⚠️ Для MVP-теста достаточно 3 шаблонов: `cover`, `big_number`, `outro_cta`. Остальные можно добавлять по мере необходимости.

## Brand anchors — что фиксированно в каждом шаблоне

См. `docs/brand-dna.md` для полной спеки. Кратко на каждом шаблоне:

- **Background**: `<img>` тег с переменной `{{bg_image_url}}` (Replicate retrofuture bg) + `rgba(26,13,58,0.65)` dim overlay + grid pattern
- **Top header**: `{{topic_label}}` слева 60×80, `{{year}}` справа 1020×80 — JetBrains Mono Bold 26px белый
- **Page counter pill**: bottom-left `60, 1270`, 120×50, white bg, content `{{page_counter}}` (e.g. "2/7")
- **TRAFFNEWS pill**: bottom-right `820, 1270`, 200×50, white bg, content фикс "TRAFFNEWS"
- **Footer text**: между pills, "Подробнее на traffnews.com" Inter 22px opacity 0.85
- **Palette**: bg `#1a0d3a`, accent `#e8f045`, text `#ffffff`

## Fonts

Все шаблоны импортируют через Google Fonts CDN:
```css
@import url('https://fonts.googleapis.com/css2?family=Anton&family=Inter:wght@400;500;700;900&family=JetBrains+Mono:wght@700&display=swap');
```

- **Anton** — заменяет Impact / Arial Black (для больших цифр / заголовков)
- **Inter** — body, subtitles (weights 400/500/700/900)
- **JetBrains Mono** — top header (typewriter look, заменяет Courier New)
