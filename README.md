# Traffnews Posting — Cloud Pipeline (Make + APITemplate.io)

**Статус:** 🟢 Архитектура зафиксирована · v1 MVP — TG article-announce карусели · полностью в облаке, без кода и без папок с проектом

Автогенерация постов для `@traffnews` (Telegram). Вход — URL статьи с traffnews.com. Выход — пост с карусельью 5-10 слайдов, опубликованный в канал.

## Архитектура в одном абзаце

**Никакого Java, никакого Docker, никаких папок с проектом.** Всё живёт в облаке у 5 SaaS-сервисов которые общаются между собой по HTTP. Make.com оркестрирует, OpenAI пишет тексты, Replicate генерит retrofuture-фоны, APITemplate.io рендерит слайды из HTML-шаблонов, Telegram Bot API публикует.

```
┌──────────────────────────────────────────────────────────────┐
│  ОБЛАКО (на твоём компе — только браузер)                    │
│                                                               │
│  ┌──────────────┐    ┌──────────────────┐                    │
│  │  Make.com    │◄──►│  apitemplate.io  │                    │
│  │  Сценарий    │    │  9 HTML-шаблонов │                    │
│  │  из 6 нод    │    │  (по типам)      │                    │
│  └──────┬───────┘    └──────────────────┘                    │
│         │                                                     │
│         ├─► OpenAI API (PostDirector — текст + brief)        │
│         ├─► Replicate (retrofuture фон через Recraft v3)     │
│         ├─► APITemplate.io (рендер каждого слайда)           │
│         └─► Telegram Bot API (sendMediaGroup → @traffnews)   │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Что эта папка теперь содержит

`D:\Prog\Постинг\` — **только документация и визуальные референсы**, никакого кода.

```
D:\Prog\Постинг\
├── README.md                        ← ты здесь
├── CLAUDE.md                        ← fresh-agent entry point (читать первым)
├── docs/
│   ├── architecture-make.md         ← полная архитектура: сервисы, потоки данных, JSON-схемы
│   ├── setup-guide.md               ← пошаговая инструкция настройки (Make + APITemplate аккаунты)
│   ├── brand-dna.md                 ← цвета, шрифты, anchors, style-family rule (для HTML-шаблонов)
│   ├── director-prompt-article.md   ← финальный промпт для OpenAI-ноды в Make
│   ├── types-roadmap.md             ← 5 типов постов (TG-MVP = article-announce)
│   ├── slide-templates/             ← готовые HTML-шаблоны для APITemplate.io
│   │   ├── slide-02-big-number.html
│   │   └── (другие появятся по мере разработки)
│   └── _stale/                      ← устаревшие doc'и от Java-эпохи (для истории)
│       ├── post-pipeline.md
│       ├── integration-plan.md
│       └── bundle-spec.md
└── preview/                         ← визуальные референсы для дизайна HTML-шаблонов
    ├── slide-01-cover.svg ... slide-07-outro.svg  ← reference design 7 слайдов
    ├── slide-02-hybrid.svg          ← PoC гибрида AI-bg + content layer
    ├── poc-bg-clean.png             ← пример retrofuture-фона от Replicate
    └── pixelarticons/svg/           ← icon pack 800 SVG (источник иконок для inline-embed в HTML)
```

## Что выходит на выходе

Post в канале `@traffnews`:
- **Caption** (до 1024 символов, HTML-формат с кликабельной ссылкой на оригинал статьи)
- **Карусель 5-10 слайдов** (1080×1350, AI-фон + brand-anchors + content)
- **Хэштеги** (1-2 для TG)

Пример визуала — `preview/slide-02-hybrid-v2.png` (PoC из сессии разработки).

## Что нужно сделать чтобы запустить (один раз)

| Этап | Время | Кто |
|---|---|---|
| Регистрация на Make.com + APITemplate.io | 5 мин | Ты |
| Создать 9 HTML-шаблонов в APITemplate (вставить готовый код из `docs/slide-templates/`) | 30-60 мин | Ты или программист |
| Собрать сценарий в Make.com по `docs/setup-guide.md` | 1-2 часа | Программист |
| Подключить API-ключи (OpenAI, Replicate, APITemplate, Telegram Bot) | 10 мин | Программист |
| Тестовый прогон + отладка | 1 час | Ты + программист |

**Дальше — 0 минут в день**, всё работает автоматически по RSS-триггеру или по нажатию кнопки.

## Старт работы

Открыть [`CLAUDE.md`](./CLAUDE.md) — там fresh-agent entry point с текущей картиной.

Полная архитектура — [`docs/architecture-make.md`](./docs/architecture-make.md).
Пошаговый setup — [`docs/setup-guide.md`](./docs/setup-guide.md).

## Notion

https://www.notion.so/35dde7a6942a81e1a731e9bb58edb73c
