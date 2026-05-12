# Traffnews Posting — Fresh Agent Entry Point

## ⚠️ Самое важное (прочитай в первую очередь)

**Этот проект — НЕ код.** Никакого Java, никакого Python, никаких папок с исходниками. Весь pipeline живёт в **облаке** у 5 SaaS-сервисов и оркестрируется через **Make.com**.

Эта папка (`D:\Prog\Постинг\`) содержит **только**:
- Документацию (что/как/почему)
- HTML-шаблоны слайдов в `docs/slide-templates/` — **Make подгружает их через HTTP при каждом прогоне** и передаёт в HCTI (htmlcsstoimage.com) для рендера. НЕТ ручной работы в UI HCTI.
- Визуальные референсы (preview/) — SVG-прототипы для понимания дизайна

**Никакого Java-кода больше не пишем.** Предыдущие планы по `D:\Prog\SMM\scripts\java\src\main\java\com\traffnews\smm\post\` — **отменены**. Соответствующие doc'и в `docs/_stale/`.

## Архитектура одним абзацем

```
RSS traffnews.com  →  Make.com сценарий:
    1. Fetch article HTML
    2. OpenAI (PostDirector промпт) → JSON brief с slides[5-10]
    3. Replicate (Recraft v3) → retrofuture AI-фон (URL)
    4. Iterator: для каждого slide →
         a) Build HTML (substitute {{vars}} в шаблон из docs/slide-templates/*.html)
         b) POST в HCTI /v1/image → PNG URL
    5. Aggregator → массив PNG-URL'ов
    6. Telegram Bot API sendMediaGroup → пост в @traffnews
```

Полная диаграмма + схемы данных — [`docs/architecture-make.md`](./docs/architecture-make.md).

## Где живёт что

| Артефакт | Где |
|---|---|
| Сценарий Make (6 нод) | make.com → аккаунт пользователя |
| HTML-шаблоны слайдов | **`docs/slide-templates/*.html` в этом репо** — Make подгружает на каждом прогоне |
| HCTI render | hcti.io API (через basic auth user_id+api_key) — рендерит каждый прогон без сохранения шаблонов |
| API-ключи | Спрятаны в Make Connections + `D:\Prog\SMM\.env` |
| Бренд-конфиг (цвета, шрифты, anchors) | `docs/brand-dna.md` |
| PostDirector OpenAI-промпт | `docs/director-prompt-article.md` |
| Визуальные референсы | `preview/*.svg`, `D:\Prog\smm-posting-poc\hcti-test-slide-02.png` |
| Pixelarticons icon pack (для inline-SVG в HTML) | https://pixelarticons.com/free-cliparts (через сайт), fallback в `preview/pixelarticons/svg/` |

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
| Настроить Make + HCTI с нуля | `docs/setup-guide.md` |
| Создать/правка HTML-шаблона | `docs/slide-templates/*.html` + `docs/brand-dna.md` |
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
- Менять архитектуру без явного запроса пользователя (мы уже сделали 9+ pivot'ов, фиксируемся на Make+HCTI)

## Состояние на 2026-05-12

- ✅ Архитектура зафиксирована: Make + HCTI + Replicate + OpenAI + Telegram
- ✅ PoC валидирован: HCTI рендер нашего HTML работает end-to-end (`D:\Prog\smm-posting-poc\hcti-test-slide-02.png`)
- ✅ Brand DNA задокументирован
- ✅ PostDirector промпт финализирован
- ✅ API-ключи готовы: OpenAI, Replicate, HCTI (HCTI_USER_ID + HCTI_API_KEY) — все в `D:\Prog\SMM\.env`
- ✅ Make.com + HCTI акки зарегистрированы (email: infonovainnovationss@gmail.com)
- 🟡 HTML-шаблоны — 1 из 9 готов (`slide-02-big-number.html`, валидирован через HCTI)
- 🟡 Make-сценарий — не собран ещё
- 🟡 Telegram Bot Token — TODO (создать через @BotFather, добавить в @traffnews как админ)

## Следующий шаг

1. ✅ Регистрации на make.com + hcti сделаны, ключи в `.env`
2. ✅ PoC рендер через HCTI API валидирован
3. 🟡 Написать остальные 8 HTML-шаблонов (cover/quote/bullet/numbered/service/compare/faq/outro)
4. 🟡 Создать Telegram Bot через @BotFather, добавить в @traffnews как админ
5. 🟡 Собрать Make-сценарий из 6 нод по `docs/architecture-make.md`
