#!/usr/bin/env bash
# Hook для отправки уведомлений в Telegram при событиях Claude Code

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_FILE="$SCRIPT_DIR/notify.log"

# Функция логирования ошибок
log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Загрузка переменных из .env
load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    log_error "Error: .env file not found at $ENV_FILE"
    exit 0
  fi

  while IFS='=' read -r key value; do
    # Пропускаем пустые строки и комментарии
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

    # Убираем кавычки и пробелы
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//')

    case "$key" in
      TELEGRAM_BOT_TOKEN) BOT_TOKEN="$value" ;;
      TELEGRAM_CHAT_ID) CHAT_ID="$value" ;;
      NOTIFICATIONS_ENABLED) NOTIFICATIONS_ENABLED="$value" ;;
      NOTIFICATION_LEVEL) NOTIFICATION_LEVEL="$value" ;;
    esac
  done < "$ENV_FILE"

  if [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    log_error "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in .env"
    exit 0
  fi
}

# Экранирование HTML спецсимволов для Telegram
escape_html() {
  local text="$1"
  text="${text//&/&amp;}"
  text="${text//</&lt;}"
  text="${text//>/&gt;}"
  text="${text//\"/&quot;}"
  echo "$text"
}

# Обрезка длинного текста
truncate_text() {
  local text="$1"
  local max_length="${2:-200}"

  if [ ${#text} -gt $max_length ]; then
    echo "${text:0:$max_length}..."
  else
    echo "$text"
  fi
}

# Отправка сообщения в Telegram
send_telegram_message() {
  local message="$1"
  local url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

  # Экранируем кавычки для JSON
  message="${message//\\/\\\\}"
  message="${message//\"/\\\"}"

  local json_payload
  json_payload=$(cat <<EOF
{
  "chat_id": "${CHAT_ID}",
  "text": "$(echo -e "$message")",
  "parse_mode": "HTML"
}
EOF
)

  local response
  response=$(curl -s -X POST "$url" \
    -H "Content-Type: application/json" \
    -H "User-Agent: Bash-Telegram-Notifier/1.0" \
    -d "$json_payload" \
    --max-time 10)

  if ! echo "$response" | grep -q '"ok":true'; then
    log_error "Telegram API error: $response"
  fi
}

# Основная логика
main() {
  # Получаем timestamp для логирования
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Загружаем конфигурацию
  load_env

  # Проверка, включены ли уведомления
  ENABLED="${NOTIFICATIONS_ENABLED:-true}"
  if [ "$ENABLED" != "true" ]; then
    exit 0
  fi

  # Читаем JSON из stdin
  INPUT=$(cat)

  # Извлекаем имя события
  EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // .hookEventName // .event // "unknown"')

  # Получаем уровень детализации
  LEVEL="${NOTIFICATION_LEVEL:-detailed}"

  # Формируем сообщение в зависимости от события
  case "$EVENT" in
    "Stop")
      MESSAGE="🛑 <b>Claude Code завершил работу</b>"
      ;;
    "PermissionRequest")
      # Извлекаем данные из JSON
      TOOL=$(echo "$INPUT" | jq -r '.tool_name // .tool // .toolName // "unknown"')
      DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // .description // .desc // empty')
      FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pathInProject // .file_path // .path // .pathInProject // .filePath // empty')
      COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // .command // .cmd // empty')

      if [ "$LEVEL" = "minimal" ]; then
        # Минимальное сообщение
        MESSAGE="⚠️ <b>Требуется разрешение:</b> <code>$(escape_html "$TOOL")</code>"
      else
        # Детальное сообщение
        MESSAGE="⚠️ <b>Требуется разрешение</b>\n\n"
        MESSAGE+="<b>Инструмент:</b> <code>$(escape_html "$TOOL")</code>"

        if [ -n "$DESCRIPTION" ] && [ "$DESCRIPTION" != "null" ]; then
          DESCRIPTION=$(truncate_text "$DESCRIPTION" 150)
          MESSAGE+="\n<b>Действие:</b> $(escape_html "$DESCRIPTION")"
        fi

        if [ -n "$FILE_PATH" ] && [ "$FILE_PATH" != "null" ]; then
          MESSAGE+="\n<b>Файл:</b> <code>$(escape_html "$FILE_PATH")</code>"
        fi

        if [ -n "$COMMAND" ] && [ "$COMMAND" != "null" ]; then
          COMMAND=$(truncate_text "$COMMAND" 200)
          MESSAGE+="\n<b>Команда:</b> <code>$(escape_html "$COMMAND")</code>"
        fi
      fi
      ;;
    *)
      MESSAGE="📢 <b>Claude Code:</b> событие $(escape_html "$EVENT")"
      ;;
  esac

  # Отправляем уведомление
  send_telegram_message "$MESSAGE" 2>/dev/null || {
    log_error "Failed to send message: $MESSAGE"
  }
}

# Запускаем main и всегда возвращаем успех, чтобы не блокировать работу Claude
main || true
exit 0
