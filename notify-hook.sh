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
    esac
  done < "$ENV_FILE"

  if [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    log_error "Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in .env"
    exit 0
  fi
}

# Отправка сообщения в Telegram
send_telegram_message() {
  local message="$1"
  local url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

  local json_payload
  json_payload=$(cat <<EOF
{
  "chat_id": "${CHAT_ID}",
  "text": "${message}",
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
  EVENT=$(echo "$INPUT" | jq -r '.hookEventName // "unknown"')

  # Формируем сообщение в зависимости от события
  case "$EVENT" in
    "Stop")
      MESSAGE="🛑 Claude Code завершил работу"
      ;;
    "PermissionRequest")
      TOOL=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
      MESSAGE="⚠️ Claude Code запрашивает подтверждение для: $TOOL"
      ;;
    *)
      MESSAGE="📢 Claude Code: событие $EVENT"
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
