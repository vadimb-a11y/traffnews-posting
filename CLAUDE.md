# Traffnews Posting — Fresh Agent Entry Point

## ⚠️ Самое важное (прочитай в первую очередь)

**Этот проект — НЕ код.** Никакого Java, никакого Python, никаких папок с исходниками на компе. Весь pipeline живёт в **облаке** у 5 SaaS-сервисов и оркестрируется через **Make.com**.

Эта папка (`D:\Prog\Постинг\`) содержит **только**:
- Документацию (что/как/почему)
- Готовые HTML-шаблоны для APITemplate.io (под копипаст в их UI)
- Визуальные референсы (preview/) — SVG-прототипы для понимания дизайна

**Никакого Java-кода больше не пишем.** Предыдущие планы по `D:\Prog\SMM\scripts\java\src\main\java\com\traffnews\smm\post\` — **отменены**. Соответствующие doc'и помечены `_stale/`.

## Архитектура одним абзацем

```
RSS traffnews.com  →  Make.com сценарий:
    1. Fetch article HTML
    2. OpenAI (PostDirector промпт) → JSON brief с slides[5-10]
    3. Replicate (Recraft v3) → retrofuture AI-фон
    4. Iterator: для каждого slide → APITemplate.io render HTML→PNG
    5. Aggregator → массив PNG
    6. Telegram Bot API sendMediaGroup → пост в @traffnews
```

Полная диаграмма + схемы данных — [`docs/architecture-make.md`](./docs/architecture-make.md).

## Где живёт что

| Артефакт | Где |
|---|---|
| Сценарий Make (6 нод) | make.com → аккаунт пользователя |
| 9 HTML-шаблонов слайдов | apitemplate.io → аккаунт пользователя |
| API-ключи (OpenAI, Replicate, APITemplate, Telegram Bot) | Спрятаны в Make Connections |
| **Готовый HTML-код шаблонов** (под копипаст) | `docs/slide-templates/*.html` (в этой папке) |
| Бренд-конфиг (цвета, шрифты, anchors) | `docs/brand-dna.md` (в этой папке) |
| PostDirector OpenAI-промпт | `docs/director-prompt-article.md` (в этой папке) |
| Визуальные референсы | `preview/*.svg`, `preview/slide-02-hybrid-v2.png` |
| Pixelarticons icon pack (для inline-SVG в HTML) | `preview/pixelarticons/svg/` |

## HARD RULES (применимы из SMM-проекта)

Хотя кода нет, **контентные правила** из `D:\Prog\SMM\CLAUDE.md` применимы к промпту PostDirector в OpenAI-ноде:

1. **Темы — только с traffnews.com.** Не выдумывать generic SMM-темы.
2. **Только русский в captions.** Phonetic anglicisms: `Гугл{Google}`, `Фейсбук{Facebook}` — для читабельности на мобильном.
3. **NO fabricated facts.** Каждое утверждение — прямо из источника статьи. Числа реальные.
4. **5-block caption structure**: HOOK / CONTEXT / STAKES («Из-за этого…») / MECHANICS («собрали…») / CTA с обязательной `<a href>` ссылкой на статью.
5. **1024 символа лимит TG-caption** — иначе пост обрезается.

Все эти правила уже закодированы в `docs/director-prompt-article.md` — этот промпт скармливается OpenAI-ноде в Make как есть.

## Какой файл открывать под какую задачу

| Задача | Файл |
|---|---|
| Понять как всё устроено end-to-end | `docs/architecture-make.md` |
| Настроить Make + APITemplate с нуля | `docs/setup-guide.md` |
| Создать HTML-шаблон в APITemplate | `docs/slide-templates/*.html` + `docs/brand-dna.md` |
| Промпт для OpenAI ноды | `docs/director-prompt-article.md` |
| Brand voice / fabrication / phonetic rules | `D:\Prog\SMM\CLAUDE.md` (source of truth) |
| Другие типы постов (vacancies/digest/...) | `docs/types-roadmap.md` (deferred) |
| Спека автопубликации в Dashboard (v3) | `docs/v2-publication/` (deferred) |

## Do / Don't

✅ Делать:
- Писать/обновлять HTML-шаблоны в `docs/slide-templates/`
- Обновлять `docs/director-prompt-article.md` если меняется промпт для PostDirector
- Использовать `preview/` SVG-прототипы как визуальный референс при дизайне HTML-шаблонов
- Сохранять Brand DNA invariants (палитра, anchors, шрифты) при создании новых шаблонов
- Anti-fabrication: каждое утверждение от Director'а — из источника

❌ Не делать:
- Писать Java/Python/Node код для самого pipeline
- Создавать папки `D:\Prog\SMM\scripts\java\...\post\` (этот план отменён)
- Дублировать HARD RULES сюда (источник — `D:\Prog\SMM\CLAUDE.md`)
- Менять архитектуру без явного запроса пользователя (мы уже сделали 8+ pivot'ов, фиксируемся на Make+APITemplate)

## Состояние на 2026-05-11

- ✅ Архитектура зафиксирована: Make + APITemplate.io + Replicate + OpenAI + Telegram
- ✅ PoC валидирован: retrofuture AI-фон (Recraft v3) + SVG content-layer гибрид работает (`preview/slide-02-hybrid-v2.png`)
- ✅ Brand DNA задокументирован
- ✅ PostDirector промпт финализирован
- 🟡 HTML-шаблоны для APITemplate — 1 из 9 готов (big_number), остальные 8 — TODO
- 🟡 Make-сценарий — не собран ещё
- 🟡 API-ключи — частично готовы (OpenAI + Replicate в `D:\Prog\SMM\.env`), Telegram Bot Token — TODO

## Следующий шаг

1. Пользователь регистрируется на make.com + apitemplate.io
2. Создаёт первый HTML-шаблон в APITemplate (slide-02-big-number) — копипаст из `docs/slide-templates/slide-02-big-number.html`
3. Тестовый рендер через API Console APITemplate — убеждаемся что результат идентичен `preview/slide-02-hybrid-v2.png`
4. Если ОК — пишем остальные 8 шаблонов, собираем Make-сценарий
