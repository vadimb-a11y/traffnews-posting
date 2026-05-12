# Setup Guide — From Zero to Working Pipeline

Пошаговая инструкция как с нуля настроить весь pipeline. Делается **один раз**.

## Что нужно подготовить заранее

- [x] **Email** для регистрации — `infonovainnovationss@gmail.com`
- [x] **OpenAI API key** в `D:\Prog\SMM\.env`
- [x] **Replicate API token** в `D:\Prog\SMM\.env`
- [x] **HCTI credentials** (HCTI_USER_ID + HCTI_API_KEY) в `D:\Prog\SMM\.env`
- [ ] **Telegram Bot token** — создать через @BotFather: `/newbot` → следовать инструкциям
- [ ] **Bot добавлен** админом в канал `@traffnews` (Settings → Administrators → Add Admin → найти своего бота)

## ЭТАП 1 — Регистрация в облачных сервисах ✅ DONE

### 1.1 Make.com ✅
- https://www.make.com — Sign up with Google
- Free план: 1000 ops/мес = ~50 постов/мес

### 1.2 HCTI / htmlcsstoimage.com ✅
- https://htmlcsstoimage.com — Sign up
- Free план: 50 рендеров/мес = ~7 карусел'ей/мес
- API Keys → Create New Key → скопировать `ID` и `API Key`

## ЭТАП 2 — HTML-шаблоны (БЕЗ UI работы)

С HCTI не нужно создавать шаблоны в их UI. Шаблоны живут **в этом репо** в `docs/slide-templates/*.html` и Make сам подставляет их через переменные при каждом прогоне.

Статус шаблонов (см. `docs/slide-templates/README.md`):

| visual_intent | Файл | Статус |
|---|---|---|
| cover | `slide-01-cover.html` | ✅ |
| big_number | `slide-02-big-number.html` | ✅ (валидирован через HCTI) |
| quote_block | `slide-03-quote.html` | 🟡 TODO |
| bullet_list | `slide-04-bullet-list.html` | ✅ |
| numbered_list | `slide-05-numbered-list.html` | 🟡 TODO |
| service_list | `slide-06-service-list.html` | 🟡 TODO |
| compare_split | `slide-07-compare.html` | 🟡 TODO |
| faq | `slide-08-faq.html` | 🟡 TODO |
| outro_cta | `slide-09-outro-cta.html` | ✅ |

**Для первого MVP-теста хватит 4 готовых** (cover, big_number, bullet_list, outro_cta) — покрывают базовую структуру статьи.

## ЭТАП 3 — Сборка Make.com сценария (1-2 часа)

### 3.1 Создать сценарий
1. Make Dashboard → **+ Create a new scenario**
2. Назвать `traffnews-article-announce`

### 3.2 Добавить шаблоны как Scenario Variables

В сценарии: **Scenario settings → Variables** → создать переменные:

- `TMPL_COVER` — paste содержимое `docs/slide-templates/slide-01-cover.html`
- `TMPL_BIG_NUMBER` — paste содержимое `docs/slide-templates/slide-02-big-number.html`
- `TMPL_BULLET` — paste содержимое `docs/slide-templates/slide-04-bullet-list.html`
- `TMPL_OUTRO` — paste содержимое `docs/slide-templates/slide-09-outro-cta.html`

(Добавляешь остальные 5 переменных по мере написания соответствующих шаблонов.)

### 3.3 Добавить ноды по очереди

Следуй структуре в [`architecture-make.md`](./architecture-make.md) раздел «Шаги сценария».

Кратко:

| # | Module | Что делает |
|---|---|---|
| 1 | HTTP > Make a request (GET) | Fetch article HTML |
| 2 | OpenAI > Create Completion | PostDirector → brief JSON |
| 3 | HTTP > Make a request (POST) | Replicate retrofuture bg |
| 4 | Flow Control > Iterator | Loop по slides[] |
| 5a | Tools > Set variable | Pick template (switch по visual_intent) + replace {{vars}} |
| 5b | HTTP > Make a request (POST) | HCTI /v1/image — рендер → PNG URL |
| 6 | Aggregator + Telegram Bot > Send Media Group | Финальный пост |

### 3.4 Подключить API-ключи (Connections)

Для каждой ноды требующей auth — Make попросит создать **Connection**:
- OpenAI: вставить API key
- Replicate: header `Authorization: Bearer {{REPLICATE_API_TOKEN}}`
- HCTI: HTTP Basic — username=HCTI_USER_ID, password=HCTI_API_KEY
- Telegram: вставить Bot Token

⚠️ **Никогда не вставлять ключ открытым текстом в URL или Body** — только через Connection.

### 3.5 Тестовый прогон

1. В сценарии нажать **Run once**
2. Если триггер — webhook: скопировать webhook URL, послать тест:
   ```
   POST <webhook_url>
   { "article_url": "https://traffnews.com/news/..." }
   ```
3. Смотреть как ноды отрабатывают одна за другой
4. На каждой ноде Make показывает input/output — отладка наглядная

### 3.6 Активация

После успешного теста — переключатель **Scheduling: ON** + интервал (например, каждые 30 минут проверка RSS).

## ЭТАП 4 — Telegram Bot (10 мин)

1. В Telegram открыть `@BotFather`
2. `/newbot` → имя бота (например `traffnews_poster_bot`) → username
3. Получишь токен типа `1234567890:AAEhBP...`
4. Открыть канал `@traffnews` → Manage Channel → Administrators → Add Admin → найти своего бота
5. Дать права: **Post Messages**, **Edit Messages of Others** (опционально)
6. Токен скопировать в Make Connection `telegram-traffnews-bot`

## ЭТАП 5 — Финальный sanity check

После всех настроек:
1. Послать тестовую статью через webhook
2. В Make видишь все 6 нод зелёные
3. В `@traffnews` появилось сообщение с карусел'ью 5-10 PNG + caption + кликабельная ссылка
4. Кликаешь на ссылку в caption — открывается оригинал статьи
5. Слайды читаемы, цифры точные, brand-anchors на месте

✅ Если всё ОК — pipeline в проде.

## Поддержка после запуска

- **Мониторинг**: Make сам шлёт уведомления о фейлах на email + telegram (настраивается в Scenario Settings → Error Handling)
- **Логи**: Каждый прогон логируется в History в Make UI, видно input/output каждой ноды
- **Изменения**:
  - Поменять промпт PostDirector — обновить `docs/director-prompt-article.md` + скопировать в OpenAI-ноду
  - Поменять дизайн слайда — обновить HTML в `docs/slide-templates/*.html` + скопировать в соответствующий Scenario Variable
  - Добавить новый тип слайда — расширить промпт PostDirector + новый HTML-шаблон + расширить switch в Node 5a

## Checklist для готовности к запуску

- [x] Make.com акк создан
- [x] HCTI акк создан
- [ ] Telegram Bot создан, добавлен в @traffnews как админ
- [x] OpenAI API ключ сохранён
- [x] Replicate токен сохранён
- [x] HCTI credentials сохранены
- [x] Минимум 4 HTML-шаблона готовы (cover, big_number, bullet_list, outro_cta)
- [ ] Make-сценарий собран и протестирован end-to-end
- [ ] Тестовый пост успешно ушёл в канал
- [ ] Scheduling: ON
