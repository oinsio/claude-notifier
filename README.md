# Telegram Notifier для Claude Code

Минимальный bash-скрипт для отправки уведомлений в Telegram при событиях Claude Code.

## Установка

1. Создайте `.env` файл на основе `.env.example`:
```bash
cp .env.example .env
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
```

Параметры:
- `NOTIFICATION_LEVEL` - уровень детализации уведомлений:
  - `detailed` (по умолчанию) - полная информация (описание, файлы, команды)
  - `minimal` - краткие сообщения (только событие и инструмент)

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

### События hooks

- **Stop** - Claude завершает работу (включая `/clear`, `/resume`)
- **PermissionRequest** - Claude запрашивает подтверждение действия

### Формат уведомлений

Уведомления содержат развёрнутую информацию о событиях:

**PermissionRequest:**
- Название инструмента (Bash, Edit, Write и т.д.)
- Описание действия
- Путь к файлу (для файловых операций)
- Текст команды (для Bash команд, обрезается до 200 символов)

**Stop:**
- Уведомление о завершении работы Claude Code

Все сообщения форматируются с использованием HTML разметки Telegram для лучшей читаемости.

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

## Логирование

Ошибки записываются в файл `notify.log` в той же директории.
