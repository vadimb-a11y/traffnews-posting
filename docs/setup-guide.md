# Setup Guide — From Zero to Working Pipeline

Пошаговая инструкция как с нуля настроить весь пайплайн. Делается **один раз**.

## Что нужно подготовить заранее

- [ ] Email для регистрации (можно gmail который уже используется)
- [ ] OpenAI API key (если ещё нет — `platform.openai.com/api-keys` → Create new key)
- [ ] Replicate API token (уже есть в `D:\Prog\SMM\.env` как `REPLICATE_API_TOKEN`)
- [ ] Telegram Bot token (создать через @BotFather: `/newbot` → следовать инструкциям)
- [ ] Bot добавлен админом в канал `@traffnews` (Settings → Administrators → Add Admin → найти своего бота)

## ЭТАП 1 — Регистрация в облачных сервисах (5 минут)

### 1.1 Make.com
1. Открыть https://www.make.com/en/register
2. Sign up with Google (тем же email)
3. После регистрации — попадёшь в Dashboard, тариф **Free** активен сразу (1000 ops/мес)
4. **Запиши**: email + пароль

### 1.2 APITemplate.io
1. Открыть https://apitemplate.io/signup
2. Sign up with Google
3. После регистрации — попадёшь в Dashboard
4. Тариф **Free Forever** (50 рендеров/мес)
5. Перейти в **Account → API Integration** → скопировать **API key**
6. **Запиши**: API key

## ЭТАП 2 — Создание HTML-шаблонов в APITemplate (30-60 мин)

Делается для **каждого** из 9 типов слайдов. Начинаем с `slide-02-big-number` (он у нас готов).

### 2.1 Создать первый шаблон

1. В APITemplate.io Dashboard нажать **+ New Template**
2. Выбрать тип **HTML to Image**
3. Назвать `traffnews_big_number`
4. Размер: **Custom**, **Width 1080**, **Height 1350**
5. В редакторе слева — три вкладки: **HTML**, **CSS**, **Sample Data**
6. Вкладка **HTML**: скопировать содержимое из `docs/slide-templates/slide-02-big-number.html` (раздел `<body>` без `<html>/<head>`)
7. Вкладка **CSS**: скопировать содержимое из того же файла (раздел `<style>`)
8. Вкладка **Sample Data**: вставить тестовый JSON:
   ```json
   {
     "bg_image_url": "https://replicate.delivery/.../bg.png",
     "topic_label": "Сокращения 2026",
     "year": "2026",
     "big_number": "26%",
     "subline_1": "всех увольнений в США в апреле",
     "subline_2": "2026 — напрямую из-за ИИ",
     "secondary_yellow": "21 490 рабочих мест",
     "secondary_white": "за один месяц.",
     "body_text": "И это число будет только расти. В отчётах компаний ИИ теперь — конкретная строка в причинах массовых сокращений, а не туманная «оптимизация».",
     "page_counter": "2/7"
   }
   ```
9. Справа в **Preview** должно появиться превью слайда — сверь с `preview/slide-02-hybrid-v2.png`
10. Нажать **Save** → запомнить **Template ID** (обычно показывается сверху, формат `12abc34def`)
11. **Запиши в таблицу** template_id ↔ visual_intent

### 2.2 Повторить для остальных 8 типов

| visual_intent | Файл шаблона | Template ID |
|---|---|---|
| cover | `slide-templates/slide-01-cover.html` | _записать_ |
| big_number | `slide-templates/slide-02-big-number.html` | _записать_ |
| quote_block | `slide-templates/slide-03-quote.html` | _записать_ |
| bullet_list | `slide-templates/slide-04-bullet-list.html` | _записать_ |
| numbered_list | `slide-templates/slide-05-numbered-list.html` | _записать_ |
| service_list | `slide-templates/slide-06-service-list.html` | _записать_ |
| compare_split | `slide-templates/slide-07-compare.html` | _записать_ |
| faq | `slide-templates/slide-08-faq.html` | _записать_ |
| outro_cta | `slide-templates/slide-09-outro.html` | _записать_ |

⚠️ Шаблоны под нумерацией 03-09 ещё **не написаны** — это TODO задача, делается **по мере необходимости** (можно стартовать только с `big_number`, `cover`, `outro_cta` для первого MVP-теста и добавлять остальные позже).

## ЭТАП 3 — Сборка Make.com сценария (1-2 часа)

### 3.1 Создать сценарий
1. Make Dashboard → **+ Create a new scenario**
2. Назвать `traffnews-article-announce`

### 3.2 Добавить ноды по очереди

Следуй структуре в [`architecture-make.md`](./architecture-make.md) раздел «Шаги сценария».

Кратко:

| # | Module | Что делает |
|---|---|---|
| 1 | HTTP > Make a request (GET) | Fetch article HTML |
| 2 | OpenAI > Create Completion | PostDirector → brief JSON |
| 3 | HTTP > Make a request (POST) | Replicate retrofuture bg |
| 4 | Flow Control > Iterator | Loop по slides[] |
| 5 | HTTP > Make a request (POST) | APITemplate render slide → PNG |
| 6 | Telegram Bot > Send Media Group | Финальный пост |

### 3.3 Подключить API-ключи (Connections)

Для каждой ноды требующей auth — Make попросит создать **Connection**:
- OpenAI: вставить API key
- Replicate: вставить токен в header `Authorization: Bearer {token}`
- APITemplate: вставить API key в header `X-API-KEY: {key}`
- Telegram: вставить Bot Token

⚠️ **Никогда не вставлять ключ открытым текстом в URL или Body** — только через Connection или через переменную.

### 3.4 Тестовый прогон

1. В сценарии нажать **Run once**
2. Если триггер — webhook: скопировать webhook URL, через Postman/curl послать тест:
   ```
   POST <webhook_url>
   { "article_url": "https://traffnews.com/news/..." }
   ```
3. Смотреть как ноды отрабатывают одна за другой
4. На каждой ноде Make показывает input/output — отладка наглядная

### 3.5 Активация

После успешного теста — переключатель **Scheduling: ON** + интервал (например, каждые 30 минут проверка RSS).

## ЭТАП 4 — Создать Telegram Bot и привязать к каналу (10 мин)

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
  - Поменять дизайн слайда — обновить HTML в `docs/slide-templates/*.html` + скопировать в соответствующий шаблон APITemplate
  - Добавить новый тип слайда — расширить промпт PostDirector + новый HTML-шаблон + расширить switch в Node 5

## Checklist для готовности к запуску

- [ ] Make.com акк создан
- [ ] APITemplate.io акк создан
- [ ] Telegram Bot создан, добавлен в @traffnews как админ
- [ ] OpenAI API ключ сохранён
- [ ] Replicate токен сохранён
- [ ] Минимум 3 HTML-шаблона созданы в APITemplate (cover, big_number, outro_cta)
- [ ] Make-сценарий собран и протестирован end-to-end
- [ ] Тестовый пост успешно ушёл в канал
- [ ] Scheduling: ON
