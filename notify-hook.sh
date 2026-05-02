#!/usr/bin/env bash
# Hook для отправки уведомлений в Telegram при событиях Claude Code

set -euo pipefail

# Получаем реальный путь к скрипту (работает с symlink)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
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
      MESSENGER) MESSENGER="$value" ;;
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

  if [ ${#text} -gt "$max_length" ]; then
    echo "${text:0:$max_length}..."
  else
    echo "$text"
  fi
}

# Преобразование абсолютного пути в относительный
make_relative_path() {
  local file_path="$1"
  local cwd="${2:-$(pwd)}"

  # Если путь пустой или null, возвращаем как есть
  if [ -z "$file_path" ] || [ "$file_path" = "null" ]; then
    echo "$file_path"
    return
  fi

  # Если путь уже относительный (не начинается с /), возвращаем как есть
  if [[ ! "$file_path" =~ ^/ ]]; then
    echo "$file_path"
    return
  fi

  # Если путь начинается с CWD, обрезаем его
  if [[ "$file_path" == "$cwd"* ]]; then
    local relative="${file_path#"$cwd"}"
    # Убираем начальный slash
    relative="${relative#/}"
    echo "$relative"
  else
    # Если путь вне проекта, возвращаем только имя файла
    basename "$file_path"
  fi
}

# Подготовка данных события
prepare_event_data() {
  local input="$1"
  local event="$2"

  case "$event" in
    "PermissionRequest")
      local tool=$(echo "$input" | jq -r '.tool_name // .tool // .toolName // "unknown"')
      local description=$(echo "$input" | jq -r '.tool_input.description // .description // .desc // empty')
      local file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.pathInProject // .file_path // .path // .pathInProject // .filePath // empty')
      local command=$(echo "$input" | jq -r '.tool_input.command // .command // .cmd // empty')
      local cwd=$(echo "$input" | jq -r '.cwd // empty')

      # Преобразуем абсолютный путь в относительный
      if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
        file_path=$(make_relative_path "$file_path" "$cwd")
      fi

      echo "$tool|$description|$file_path|$command"
      ;;
    *)
      echo "$event"
      ;;
  esac
}

# Форматирование сообщения
format_message() {
  local event="$1"
  local data="$2"
  local level="$3"
  local timestamp="$4"

  local message=""

  case "$event" in
    "Stop")
      message="🛑 <b>Claude Code завершил работу</b> <i>($timestamp)</i>"
      ;;
    "PermissionRequest")
      IFS='|' read -r tool description file_path command <<< "$data"

      if [ "$level" = "minimal" ]; then
        message="⚠️ <b>Требуется разрешение:</b> <code>$(escape_html "$tool")</code> <i>($timestamp)</i>"
      else
        message="⚠️ <b>Требуется разрешение</b> <i>($timestamp)</i>\n\n"
        message+="<b>Инструмент:</b> <code>$(escape_html "$tool")</code>"

        if [ -n "$description" ] && [ "$description" != "null" ]; then
          description=$(truncate_text "$description" 150)
          message+="\n<b>Действие:</b> $(escape_html "$description")"
        fi

        if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
          message+="\n<b>Файл:</b> <code>$(escape_html "$file_path")</code>"
        fi

        if [ -n "$command" ] && [ "$command" != "null" ]; then
          command=$(truncate_text "$command" 200)
          message+="\n<b>Команда:</b> <code>$(escape_html "$command")</code>"
        fi
      fi
      ;;
    *)
      message="📢 <b>Claude Code:</b> событие $(escape_html "$event") <i>($timestamp)</i>"
      ;;
  esac

  echo "$message"
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

# Отправка уведомления (общая функция)
send_notification() {
  local message="$1"
  local messenger="${MESSENGER:-telegram}"

  case "$messenger" in
    telegram)
      send_telegram_message "$message"
      ;;
    *)
      log_error "Unknown messenger: $messenger"
      ;;
  esac
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

  # Форматируем текущее время для сообщений
  local message_time
  message_time=$(date '+%d.%m.%Y %H:%M:%S')

  # Подготавливаем данные события
  local event_data
  event_data=$(prepare_event_data "$INPUT" "$EVENT")

  # Форматируем сообщение
  local message
  message=$(format_message "$EVENT" "$event_data" "$LEVEL" "$message_time")

  # Отправляем уведомление
  send_notification "$message" 2>/dev/null || {
    log_error "Failed to send message: $message"
  }
}

# Запускаем main и всегда возвращаем успех, чтобы не блокировать работу Claude
main || true
exit 0
