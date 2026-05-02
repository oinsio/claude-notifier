#!/usr/bin/env bash
# Russian locale for Claude Code notifications

# Stop event messages
MSG_STOP_TITLE="Claude Code завершил работу"

# PermissionRequest event messages
MSG_PERMISSION_TITLE="Требуется разрешение"
MSG_PERMISSION_MINIMAL="Требуется разрешение"

# Field labels
MSG_LABEL_TOOL="Инструмент"
MSG_LABEL_ACTION="Действие"
MSG_LABEL_FILE="Файл"
MSG_LABEL_COMMAND="Команда"

# Generic event message
MSG_GENERIC_EVENT="Claude Code: событие"

# Error messages
MSG_ERROR_ENV_NOT_FOUND="Ошибка: файл .env не найден по адресу"
MSG_ERROR_TOKEN_REQUIRED="Ошибка: TELEGRAM_BOT_TOKEN и TELEGRAM_CHAT_ID должны быть установлены в .env"
MSG_ERROR_TELEGRAM_API="Ошибка Telegram API"
MSG_ERROR_UNKNOWN_MESSENGER="Неизвестный мессенджер"
MSG_ERROR_SEND_FAILED="Не удалось отправить сообщение"

# notify-toggle messages
MSG_TOGGLE_ENV_NOT_FOUND="❌ Файл .env не найден:"
MSG_TOGGLE_ENABLED="✅ Уведомления включены"
MSG_TOGGLE_DISABLED="🔕 Уведомления отключены"
MSG_TOGGLE_STATUS_ENABLED="✅ Уведомления: включены"
MSG_TOGGLE_STATUS_DISABLED="🔕 Уведомления: отключены"
MSG_TOGGLE_USAGE="Использование: notify-toggle [on|off]"
MSG_TOGGLE_USAGE_ON="  on  - включить уведомления"
MSG_TOGGLE_USAGE_OFF="  off - отключить уведомления"
MSG_TOGGLE_USAGE_STATUS="  (без аргументов) - показать текущий статус"
