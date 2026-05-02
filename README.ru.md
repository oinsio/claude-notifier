# Telegram Notifier для Claude Code

[![en](https://img.shields.io/badge/lang-en-blue.svg)](README.md)
[![ru](https://img.shields.io/badge/lang-ru-red.svg)](README.ru.md)

Минимальный bash-скрипт для отправки уведомлений в Telegram при событиях Claude Code.

## Установка

1. Создайте `.env` файл на основе `.env.sample`:
```bash
cp .env.sample .env
```

2. Получите токен бота:
   - Напишите @BotFather в Telegram
   - Создайте нового бота командой `/newbot`
   - Скопируйте токен

3. Получите Chat ID:
   - Напишите @userinfobot в Telegram
   - Скопируйте ваш ID

4. Заполните `.env`:
```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
NOTIFICATIONS_ENABLED=true
NOTIFICATION_LEVEL=detailed
MESSENGER=telegram
LANGUAGE=ru
```

Параметры:
- `NOTIFICATION_LEVEL` - уровень детализации уведомлений:
  - `detailed` (по умолчанию) - полная информация (описание, файлы, команды)
  - `minimal` - краткие сообщения (только событие и инструмент)
- `MESSENGER` - мессенджер для отправки уведомлений:
  - `telegram` (по умолчанию) - отправка в Telegram
  - В будущем: `slack`, `discord` и другие
- `LANGUAGE` - язык сообщений уведомлений:
  - `en` - английские сообщения (English messages)
  - `ru` (по умолчанию для русской версии) - русские сообщения

5. Сделайте скрипты исполняемыми:
```bash
chmod +x notify-hook.sh notify-toggle
```

## Требования

- Bash 4.0+
- `curl` (обычно предустановлен)
- `jq` (для парсинга JSON)

Установка jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```


## Интеграция с Claude Code

### Настройка hooks

1. **Для текущего проекта** (уже настроено в `.claude/settings.json`):
   - Hooks срабатывают только в этой директории
   - Уведомления отправляются при завершении работы Claude и запросах подтверждения

2. **Для глобальной настройки** (все проекты):

   Добавьте в `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "Stop": [{
         "hooks": [{
           "type": "command",
           "command": "/absolute/path/to/notify-hook.sh",
           "timeout": 10
         }]
       }],
       "PermissionRequest": [{
         "hooks": [{
           "type": "command",
           "command": "/absolute/path/to/notify-hook.sh",
           "timeout": 10,
           "async": true
         }]
       }]
     }
   }
   ```

3. **Применение изменений**:

   После добавления или изменения hooks необходимо **перезапустить Claude Code**, чтобы изменения вступили в силу. Конфигурация загружается только при старте приложения.

### События hooks

- **Stop** - Claude завершает работу (включая `/clear`, `/resume`)
- **PermissionRequest** - Claude запрашивает подтверждение действия

### Формат уведомлений

Уведомления содержат развёрнутую информацию о событиях:

**PermissionRequest:**
- Название инструмента (Bash, Edit, Write и т.д.)
- Описание действия (из `tool_input.description`)
- Путь к файлу (для файловых операций, из `tool_input.file_path` или `tool_input.pathInProject`)
- Текст команды (для Bash команд, из `tool_input.command`, обрезается до 200 символов)

**Stop:**
- Уведомление о завершении работы Claude Code

Все сообщения форматируются с использованием HTML разметки Telegram для лучшей читаемости.

### Структура JSON от Claude Code

Claude Code передаёт данные в формате:
```json
{
  "hook_event_name": "PermissionRequest",
  "tool_name": "Bash",
  "tool_input": {
    "command": "...",
    "description": "..."
  }
}
```

Скрипт автоматически извлекает нужные поля из `tool_input`.

### Тестирование

```bash
# Проверка hook напрямую
echo '{"hookEventName":"Stop"}' | ./notify-hook.sh

# Проверка логов
tail -f notify.log
```

## Управление уведомлениями

Используйте скрипт `notify-toggle` для быстрого включения/отключения уведомлений:

```bash
# Показать текущий статус
./notify-toggle

# Включить уведомления
./notify-toggle on

# Отключить уведомления
./notify-toggle off
```

Это изменяет значение `NOTIFICATIONS_ENABLED` в `.env` файле без необходимости ручного редактирования.

## Локализация

Проект поддерживает несколько языков для сообщений уведомлений. Язык настраивается через параметр `LANGUAGE` в файле `.env`.

### Доступные языки

- `en` - английский (English, по умолчанию)
- `ru` - русский

### Добавление новых языков

1. Создайте новый файл локали в директории `locales/` (например, `locales/fr.sh`)
2. Скопируйте структуру из `locales/en.sh`
3. Переведите все строки сообщений
4. Установите `LANGUAGE=fr` в файле `.env`

Пример структуры файла локали:
```bash
#!/usr/bin/env bash
# French locale for Claude Code notifications

MSG_STOP_TITLE="Claude Code a terminé"
MSG_PERMISSION_TITLE="Permission requise"
# ... другие сообщения
```

## Логирование

Ошибки записываются в файл `notify.log` в той же директории.

### Ротация логов

Скрипт автоматически ротирует лог-файлы, чтобы предотвратить неограниченный рост:

- **Максимальный размер по умолчанию**: 1 МБ (настраивается через `LOG_MAX_SIZE_MB` в `.env`)
- **Хранимых ротированных файлов**: 2 (настраивается через `LOG_KEEP_FILES`)
- **Формат ротации**: `notify.log` → `notify.log.1` → `notify.log.2`
- Самые старые файлы автоматически удаляются при достижении лимита

Настройка в `.env`:
```bash
LOG_MAX_SIZE_MB=1        # Максимальный размер лог-файла в МБ
LOG_KEEP_FILES=2         # Количество хранимых ротированных файлов
```

### Дедупликация событий

Скрипт автоматически предотвращает дублирующиеся уведомления с помощью механизма дедупликации:

- **Окно дедупликации**: 5 секунд
- **Как работает**: События с одинаковым `session_id` и типом блокируются, если происходят в течение 5 секунд
- **Хранение**: Данные дедупликации хранятся в файле `.event-dedup` (управляется автоматически)
- **Очистка**: Старые записи (старше 1 минуты) автоматически удаляются

Это предотвращает дублирующиеся уведомления, когда Claude Code вызывает один и тот же хук несколько раз для одного события.
