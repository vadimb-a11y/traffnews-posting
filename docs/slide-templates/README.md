# Slide Templates for HCTI (htmlcsstoimage.com)

Готовые HTML-шаблоны которые Make передаёт в HCTI API. **Не нужно создавать шаблоны в UI** — HCTI рендерит присланный HTML на лету.

## Workflow

```
Make scenario (на каждой итерации Iterator):
  1. Read slide.visual_intent (e.g. "big_number")
  2. Pick template — switch() в Make formula:
       "big_number" → содержимое slide-02-big-number.html
       "cover"      → содержимое slide-01-cover.html
       etc.
  3. Substitute {{variables}} (slide.big_number, slide.subline_1, ...)
  4. POST в HCTI /v1/image с готовым HTML
  5. Получить PNG URL
```

Шаблоны живут в **Scenario Variables** в Make (paste'нутые туда один раз) ИЛИ Make делает HTTP GET к raw GitHub URL'у этого файла на каждом прогоне (если репо запушен publicly).

## Список шаблонов

| # | visual_intent | Файл | Статус |
|---|---|---|---|
| 1 | cover | `slide-01-cover.html` | ✅ Готов |
| 2 | big_number | `slide-02-big-number.html` | ✅ Готов, валидирован через HCTI |
| 3 | quote_block | `slide-03-quote.html` | 🟡 TODO |
| 4 | bullet_list | `slide-04-bullet-list.html` | ✅ Готов |
| 5 | numbered_list | `slide-05-numbered-list.html` | 🟡 TODO |
| 6 | service_list | `slide-06-service-list.html` | 🟡 TODO |
| 7 | compare_split | `slide-07-compare.html` | 🟡 TODO |
| 8 | faq | `slide-08-faq.html` | 🟡 TODO |
| 9 | outro_cta | `slide-09-outro-cta.html` | ✅ Готов |

⚠️ Для **первого MVP-теста достаточно 4 готовых** (cover + big_number + bullet_list + outro_cta) — это покрывает базовую структуру статьи (опенер + большое число + список + CTA). Остальные 5 добавляем когда понадобятся.

## HCTI API payload

Каждый рендер — POST `https://hcti.io/v1/image` с такой структурой:

```json
{
  "html": "<полное содержимое <body> со всеми подставленными {{vars}}>",
  "css": "<содержимое <style> блока>",
  "google_fonts": "Anton|Inter:400,500,700,900|JetBrains+Mono:700",
  "viewport_width": 1080,
  "viewport_height": 1350,
  "device_scale": 2
}
```

Auth: HTTP Basic — `username=HCTI_USER_ID, password=HCTI_API_KEY`.

Response:
```json
{ "url": "https://hcti.io/v1/image/abc-def-..." }
```

Этот URL передаётся в Telegram sendMediaGroup без скачивания (Telegram сам потянет с CDN).

## Brand anchors — что фиксированно в каждом шаблоне

См. `docs/brand-dna.md` для полной спеки. Кратко:

- **Background**: `<img>` с переменной `{{bg_image_url}}` (Replicate retrofuture) + `rgba(26,13,58,0.55-0.65)` dim overlay + grid pattern
- **Top header**: `{{topic_label}}` слева, `{{year}}` справа — JetBrains Mono Bold 26px белый
- **Page counter pill**: bottom-left 60×1270, 120×50, white bg, `{{page_counter}}` (e.g. "2/7")
- **TRAFFNEWS pill**: bottom-right 820×1270, 200×50, white bg, фикс "TRAFFNEWS"
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

## Icons — откуда брать

**Самый простой путь** — сайт https://pixelarticons.com/free-cliparts:
1. Поиск нужной иконки (`fire`, `arrow-right`, `brackets`, `zap`, `mouse`, etc.)
2. Клик на иконку → кнопка **Copy SVG**
3. Вставить SVG-код прямо в HTML-шаблон между `<body>...</body>`
4. Стилизовать через CSS class (размер, цвет через `fill`)

Альтернатива (offline) — локальная копия пака в `D:\Prog\Постинг\preview\pixelarticons\svg\` (800 файлов, MIT).

### Style-family rule (важно)

В рамках **одной карусели** — только **одна стилевая семья** иконок:
- **Flat 1-bit pixel** (pixelarticons) — default для tech/AI/general карусел
- **3D voxel** (pxlkit) — отдельная семья, не миксить с flat
- **Line-art** (Lucide / Phosphor) — третья семья

Между разными постами семья может меняться под тематику. Внутри одного поста — одна.
