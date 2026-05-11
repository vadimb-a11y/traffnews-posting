# Brand DNA — TRAFFNEWS Carousel

Конфиг визуального стиля каруселей @traffnews. **Анкоры** обязательны на каждом слайде. **Переменные** — творчество дизайнера/директора под контент.

## Anchors (INVARIANTS — не нарушать)

Эти элементы **обязательны** на каждом слайде карусели. Они задают узнаваемость канала.

### 1. Page counter pill (bottom-left)

```
┌────┐
│ 1/7│   ← белый roundrect (radius 25), чёрный bold текст
└────┘
position: x=60, y=1270
size: 120×50
font: Inter Bold 24pt
content: "{slide_idx}/{slide_total}"
```

### 2. TRAFFNEWS pill (bottom-right)

```
┌──────────────┐
│  TRAFFNEWS   │   ← белый roundrect (radius 25), чёрный extra-bold
└──────────────┘
position: x=820, y=1270 (right-aligned)
size: 200×50
font: Inter ExtraBold 24pt (900)
content: "TRAFFNEWS" (always, верхний регистр)
```

### 3. Site URL (bottom-center between pills)

```
"Подробнее на traffnews.com"
position: x=200, y=1305
font: Inter 22pt regular
opacity: 0.85
color: #ffffff
```

### 4. Top header (top of every content slide)

```
left: "{topic_label}"         right: "{year}"
"{topic_label}"           ← top-left, x=60, y=80
"{year}"                  ← top-right, x=1020 (right-aligned), y=80
font: Courier New Bold 26pt
color: #ffffff
```

Пример для статьи «ИИ против офиса»:
- left: «Сокращения 2026»
- right: «2026»

Cover-слайд может **опускать** top header если на нём есть свой большой title-band (как в «Нейросети без цензуры» cover).

### 5. Color palette

| Назначение | Hex |
|---|---|
| Background base | `#1a0d3a` (deep purple) |
| Background glow (radial gradient) | `#5b2a8f` 60%opacity → fade to bg |
| Accent (yellow) — числа, ключевые слова, заголовки в spec_list, акценты | `#e8f045` |
| Body text | `#ffffff` |
| Pill backgrounds | `#ffffff` |
| Pill text | `#000000` |
| Grid overlay | `#ffffff` at 6% opacity |
| Dark band (cover diagonal) | `#000000` |

### 6. Grid texture (на всех слайдах)

```
pattern: 60×60 grid
stroke: #ffffff at 6% opacity
applied as full-size overlay поверх background
```

Subtle blueprint feel. Не убирать.

### 7. Canvas size

**1080 × 1350** (4:5 ratio, IG carousel friendly, TG читает то же).

---

## Variables (CREATIVE — варьировать под контент)

Здесь свобода. Главное — каждый слайд должен быть **читаем за 3 секунды на телефоне**.

### Slide types (черновой реестр)

| Тип | Когда использовать | Пример из «Нейросети без цензуры» |
|---|---|---|
| `cover` | Слайд 1, опенер | Hero photo + диагональная чёрная плашка с заголовком |
| `quote_block` | Главный факт / число / определение | «Это модели с отключенными фильтрами...» в жёлтой рамке |
| `big_number` | Один сильный показатель | 26% / 21 490 / $1 трлн (огромным шрифтом) |
| `bullet_list` | Категории / список 3-5 пунктов | «КОМУ И ЗАЧЕМ» — 5 жёлтых bullet'ов |
| `numbered_list` | Пошаговое / упорядоченное | «НА ЧТО СМОТРЕТЬ» — 5 пронумерованных |
| `service_list` | Сервисы / компании / инструменты | «ТОП СЕРВИСОВ» — жёлтое название + описание |
| `compare_split` | A vs B | TBD |
| `faq` | Вопрос-ответ × 2-3 | Последний слайд про FAQ |
| `outro_cta` | Финальный слайд | «ЧТО ДЕЛАТЬ?» + 3 пункта + CTA |

Слайды можно **миксовать** в любом порядке. Cover всегда первый, outro — обычно последний.

### Что варьируется свободно

- **Hero photo / иллюстрация на cover** — под топик (модель в фиолете, абстракт AI, метафора)
- **Положение и угол title-band** на cover (диагональ -6°, -8°, -10°)
- **Декоративные pixel-иконки** — disk, фигурные скобки `{ }` `( )`, hand-cursor, plus, X-mark — раскидывать в свободных углах
- **Порядок элементов на слайдах квот/листов** — заголовок может быть сверху / по центру / снизу
- **Расположение акцент-цветов** (yellow underline, yellow callout, yellow highlight на слове)
- **Шрифт-treatment** для заголовков секций (Impact / Russo One / Arial Black — все жирные condensed)

### Что НЕ варьировать

- Цвета вне палитры (никакого красного / синего / зелёного — только фиолетовый/жёлтый/чёрный/белый)
- Pill formatting (всегда roundrect 25px radius, белый, без border, без shadow)
- Top header в курьере (typewriter font) — не менять на sans-serif
- Размер канваса (всегда 1080×1350)

---

## Per-shot variation guidelines

- **3+ декоративных pixel-иконки** в карусели в целом (не на каждом слайде). Поддерживают retro-tech aesthetic.
- **Yellow accent должен быть** хотя бы где-то на каждом слайде — даже если контент не яркий
- **1 dominant visual element** per slide. Не четыре заголовка одновременно.
- **Mobile readability check** — текст должен читаться на 6" экране. Минимум 24pt для body, 30pt+ для заголовков.

## Design philosophy — VARIABILITY IS A FEATURE

**Не делать каждый слайд по одному шаблону.** В рамках brand-anchors (см. выше) **каждый слайд может иметь свой treatment** — это часть стиля канала, не баг:

- На одном слайде title может быть **в чёрной плашке** наискось (как cover)
- На другом — **в жёлтых блоках** прямоугольных (как slide 6 «ЭТО В АРБИТРАЖЕ»)
- На третьем — **просто крупный белый текст** с жёлтым подчёркиванием (slide 3, 4, 5)

Декоративные icon-treatments тоже варьируются:
- `pixelarticons` flat 1-bit (есть в `preview/pixelarticons/svg/`) — для большинства слайдов
- 3D-style pixel cluster (hand-drawn в SVG — disk с offset shadow) — для cover или акцентных
- Простые жёлтые `→` стрелки для bullet-маркеров

**Правило:** если визуально подходит контенту слайда — используй. Однообразие = скучно. Variability в рамках brand DNA = живо.

## Icon pack reference

### Hard rule: ONE STYLE FAMILY PER CAROUSEL

В рамках **одной карусели** (одного поста) использовать иконки **одной стилевой семьи**. Можно миксовать иконки из разных pack'ов **если они одного семейства** (например все плоские 1-bit pixel), но **нельзя миксовать разные стилевые языки** (1-bit pixel + 3D voxel в одной карусели = ломает целостность).

Стилевые семьи:
- **Flat 1-bit pixel** — pixelarticons + HackerNoon Pixel Library + hand-drawn pixel SVG. Все читаются как один стиль.
- **3D voxel / isometric pixel** — pxlkit и подобные. Отдельная семья.
- **Line-art / minimalist** — Lucide / Phosphor (не пиксельные). Совсем другая семья.

Между **разными постами** (разные карусели разных статей) можно выбирать разные семьи под тематику:
- Tech/AI/digital → flat pixel (наш default)
- Money/gambling/премиум → возможно 3D voxel для «дорогого» feel
- Минималистичное explainer → line-art

### Available packs

- **pixelarticons** [(github)](https://github.com/halfmage/pixelarticons) (800 icons, MIT, 24×24 grid, `fill="currentColor"`). Клонировано в `preview/pixelarticons/svg/`. **Default для тех / AI / general карусел.**
  - Useful names (verified): `pointer` (hand cursor), `brackets`, `memory-stick`, `chart-column-decreasing`, `fire`, `zap`, `warning-diamond`, `arrow-right`/`-left`/`-up`/`-down`, `plus`, `minus`, `circle`, `square`, `mouse`, `terminal`, `monitor`, `computer`, `database`, `file`.
- **HackerNoon Pixel Library** [(github)](https://github.com/hackernoon/pixel-icon-library) (2300+ icons, open source, 24px grid). Альтернатива для финансовых / премиальных тем.
- **pxlkit** [(github)](https://github.com/joangeldelarosa/pxlkit) (200+ icons, 3D voxel option). Для редких случаев когда нужна объёмность.

Запрещено: **hand-drawn pixel art в SVG-коде** (то что я делал в первой итерации rect'ами) — кроме случая когда никакой pack не покрывает специфическую форму. И даже тогда — оформлять в стиле выбранного pack'а карусели.

## Reference files

- `D:\Prog\Постинг\preview\slide-01-cover.svg` — cover template (iteration 2)
- `D:\Prog\Постинг\preview\slide-02-quote.svg` — quote_block / big_number template
- `D:\Prog\Постинг\preview\slide-03-list.svg` — service_list template
- `D:\Prog\Постинг\preview\shot-*.png` — Edge-headless screenshots (для proof rendering работает)

## Production rendering pipeline (placeholder для Java)

```
PostBrief (JSON from PostDirector)
       ↓
SlideTemplateSelector
  - выбирает SlideTemplate по slide.visual_intent
       ↓
SlideRenderer.render(slide, template, brandDNA)
  - выполняет SVG composition
  - подставляет brand anchors (pills, header, grid, palette)
  - подставляет content из slide
  - varies decorative elements per slide
       ↓
SvgToPng converter
  - rsvg-convert / batik / Java SVG library
  - output: PNG 1080×1350
       ↓
BundleAssembler
  - складывает slide_NN.png + tg.md + ... в bundle folder
```
