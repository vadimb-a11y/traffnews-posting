# Traffnews Posting — Cloud Pipeline (Make + HCTI)

**Статус:** 🟢 Архитектура зафиксирована · v1 MVP — TG article-announce карусели · полностью в облаке, без кода и без папок с проектом

Автогенерация постов для `@traffnews` (Telegram). Вход — URL статьи с traffnews.com. Выход — пост с карусельью 5-10 слайдов, опубликованный в канал.

## Архитектура в одном абзаце

**Никакого Java, никакого Docker.** Всё в облаке у 5 SaaS-сервисов которые общаются между собой по HTTP. **Make.com** оркестрирует, **OpenAI** пишет тексты, **Replicate** генерит retrofuture-фоны, **HCTI (htmlcsstoimage.com)** рендерит каждый слайд из HTML-шаблонов **которые лежат в этом репо** (НЕТ шаблонов в UI HCTI, всё через API), **Telegram Bot API** публикует.

```
┌──────────────────────────────────────────────────────────────┐
│  ОБЛАКО (на твоём компе — только браузер)                    │
│                                                               │
│  ┌──────────────┐                                            │
│  │  Make.com    │  ── сценарий из 6 нод                      │
│  └──────┬───────┘                                            │
│         │                                                     │
│         ├─► OpenAI API (PostDirector — текст + brief)        │
│         ├─► Replicate (retrofuture фон через Recraft v3)     │
│         ├─► HCTI / hcti.io                                   │
│         │      (рендер HTML→PNG, шаблоны грузятся из         │
│         │       docs/slide-templates/ через HTTP)            │
│         └─► Telegram Bot API (sendMediaGroup → @traffnews)   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Что эта папка теперь содержит

`D:\Prog\Постинг\` — **только документация, HTML-шаблоны и визуальные референсы**.

```
D:\Prog\Постинг\
├── README.md                        ← ты здесь
├── CLAUDE.md                        ← fresh-agent entry point (читать первым)
├── docs/
│   ├── architecture-make.md         ← полная архитектура: сервисы, потоки данных, JSON-схемы
│   ├── setup-guide.md               ← пошаговая инструкция настройки
│   ├── brand-dna.md                 ← цвета, шрифты, anchors, style-family rule
│   ├── director-prompt-article.md   ← финальный промпт для OpenAI-ноды в Make
│   ├── types-roadmap.md             ← 5 типов постов (TG-MVP = article-announce)
│   ├── slide-templates/             ← готовые HTML-шаблоны для HCTI
│   │   ├── slide-02-big-number.html ← ✅ готов, валидирован
│   │   └── (другие 8 — TODO)
│   └── _stale/                      ← устаревшие doc'и от Java-эпохи
└── preview/                         ← визуальные референсы (SVG-прототипы)
    ├── slide-01-cover.svg ... slide-07-outro.svg
    ├── slide-02-hybrid.svg
    ├── poc-bg-clean.png             ← пример retrofuture-фона от Replicate
    └── pixelarticons/svg/           ← icon pack 800 SVG (offline fallback)
```

## Что выходит на выходе

Post в канале `@traffnews`:
- **Caption** (до 1024 символов, HTML-формат с кликабельной ссылкой на оригинал статьи)
- **Карусель 5-10 слайдов** (1080×1350, AI-фон + brand-anchors + content)
- **Хэштеги** (1-2 для TG)

Пример визуала — `D:\Prog\smm-posting-poc\hcti-test-slide-02.png` (валидированный PoC через HCTI API).

## Что нужно сделать чтобы запустить (один раз)

| Этап | Время | Кто | Статус |
|---|---|---|---|
| Регистрация на Make.com + hcti.io | 5 мин | Ты | ✅ |
| API-ключи в `D:\Prog\SMM\.env` | 5 мин | Ты | ✅ |
| Создать Telegram Bot + добавить в @traffnews | 10 мин | Ты | 🟡 |
| Написать 8 оставшихся HTML-шаблонов | 1-2 часа | Я | 🟡 |
| Собрать сценарий в Make.com по `docs/setup-guide.md` | 1-2 часа | Программист | 🟡 |
| Тестовый прогон + отладка | 1 час | Ты + программист | 🟡 |

**Дальше — 0 минут в день**, всё работает автоматически.

## Старт работы

Открыть [`CLAUDE.md`](./CLAUDE.md) — там fresh-agent entry point.

Полная архитектура — [`docs/architecture-make.md`](./docs/architecture-make.md).
Пошаговый setup — [`docs/setup-guide.md`](./docs/setup-guide.md).

## Notion

https://www.notion.so/35dde7a6942a81e1a731e9bb58edb73c
