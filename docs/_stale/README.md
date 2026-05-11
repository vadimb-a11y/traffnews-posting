# Stale Docs (Java-pipeline era)

⚠️ **Эти документы устарели.** Они описывают предыдущую архитектуру — Java pipeline в `D:\Prog\SMM\scripts\java\src\main\java\com\traffnews\smm\post\`.

После сессии 2026-05-11 архитектура изменена на **облачный pipeline через Make.com + APITemplate.io** (без кода и без папок проекта).

Актуальная архитектура — см. [`../architecture-make.md`](../architecture-make.md) и [`../setup-guide.md`](../setup-guide.md).

## Что здесь полезного

- `post-pipeline.md` — описывает ABSTRACT flow (input → director → slides → output), частично применимо: концепция 5-block caption, 9 visual_intent типов, vision-verify loop как идея для будущего
- `integration-plan.md` — описывает интеграцию в SMM Java. Полностью устарело.
- `bundle-spec.md` — формат bundle-папки. Не применимо (теперь нет папок, всё в Telegram напрямую).

Оставлено для истории — не использовать как реальную спеку.
