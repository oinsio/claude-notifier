#!/usr/bin/env bash
# Hook for sending notifications to Telegram on Claude Code events

set -euo pipefail

# Get real script path (works with symlinks)
SCRIPT_PATH="${BASH_SOURCE[0]}"
while [ -L "$SCRIPT_PATH" ]; do
  SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  SCRIPT_PATH="$(readlink "$SCRIPT_PATH")"
  [[ $SCRIPT_PATH != /* ]] && SCRIPT_PATH="$SCRIPT_DIR/$SCRIPT_PATH"
done
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
LOG_FILE="$SCRIPT_DIR/notify.log"

# Rotate log file if it exceeds size limit
rotate_log_if_needed() {
  local log_file="$1"
  local max_size_mb="${LOG_MAX_SIZE_MB:-1}"
  local keep_files="${LOG_KEEP_FILES:-2}"

  # Check if log file exists
  if [ ! -f "$log_file" ]; then
    return 0
  fi

  # Calculate size in bytes
  local max_size_bytes=$((max_size_mb * 1024 * 1024))
  local current_size
  current_size=$(stat -f%z "$log_file" 2>/dev/null || echo 0)

  # Check if rotation is needed
  if [ "$current_size" -lt "$max_size_bytes" ]; then
    return 0
  fi

  # Remove oldest log file
  rm -f "${log_file}.${keep_files}"

  # Shift existing log files
  for ((i=keep_files-1; i>=1; i--)); do
    if [ -f "${log_file}.$i" ]; then
      mv "${log_file}.$i" "${log_file}.$((i+1))"
    fi
  done

  # Rotate current log file
  mv "$log_file" "${log_file}.1"
  touch "$log_file"
}

# Error logging function
log_error() {
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Rotate log if needed before writing
  rotate_log_if_needed "$LOG_FILE"

  echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Load locale file
load_locale() {
  local lang="${1:-en}"
  local locale_file="$SCRIPT_DIR/locales/${lang}.sh"

  # Fallback to English if locale file doesn't exist
  if [ ! -f "$locale_file" ]; then
    locale_file="$SCRIPT_DIR/locales/en.sh"
  fi

  if [ -f "$locale_file" ]; then
    source "$locale_file"
  else
    log_error "Error: No locale files found"
    exit 0
  fi
}

# Load variables from .env
load_env() {
  if [ ! -f "$ENV_FILE" ]; then
    log_error "$MSG_ERROR_ENV_NOT_FOUND $ENV_FILE"
    exit 0
  fi

  while IFS='=' read -r key value; do
    # Skip empty lines and comments
    [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue

    # Remove quotes and spaces
    value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//')

    case "$key" in
      TELEGRAM_BOT_TOKEN) BOT_TOKEN="$value" ;;
      TELEGRAM_CHAT_ID) CHAT_ID="$value" ;;
      NOTIFICATIONS_ENABLED) NOTIFICATIONS_ENABLED="$value" ;;
      NOTIFICATION_LEVEL) NOTIFICATION_LEVEL="$value" ;;
      MESSENGER) MESSENGER="$value" ;;
      LANGUAGE) LANGUAGE="$value" ;;
      LOG_MAX_SIZE_MB) LOG_MAX_SIZE_MB="$value" ;;
      LOG_KEEP_FILES) LOG_KEEP_FILES="$value" ;;
    esac
  done < "$ENV_FILE"

  if [ -z "${BOT_TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    log_error "$MSG_ERROR_TOKEN_REQUIRED"
    exit 0
  fi
}

# HTML escape for Telegram special characters
escape_html() {
  local text="$1"
  text="${text//&/&amp;}"
  text="${text//</&lt;}"
  text="${text//>/&gt;}"
  text="${text//\"/&quot;}"
  echo "$text"
}

# Truncate long text
truncate_text() {
  local text="$1"
  local max_length="${2:-200}"

  if [ ${#text} -gt "$max_length" ]; then
    echo "${text:0:$max_length}..."
  else
    echo "$text"
  fi
}

# Convert absolute path to relative
make_relative_path() {
  local file_path="$1"
  local cwd="${2:-$(pwd)}"

  # If path is empty or null, return as is
  if [ -z "$file_path" ] || [ "$file_path" = "null" ]; then
    echo "$file_path"
    return
  fi

  # If path is already relative (doesn't start with /), return as is
  if [[ ! "$file_path" =~ ^/ ]]; then
    echo "$file_path"
    return
  fi

  # If path starts with CWD, trim it
  if [[ "$file_path" == "$cwd"* ]]; then
    local relative="${file_path#"$cwd"}"
    # Remove leading slash
    relative="${relative#/}"
    echo "$relative"
  else
    # If path is outside project, return only filename
    basename "$file_path"
  fi
}

# Prepare event data
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

      # Convert absolute path to relative
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

# Format message
format_message() {
  local event="$1"
  local data="$2"
  local level="$3"
  local timestamp="$4"

  local message=""

  case "$event" in
    "Stop")
      message="🛑 <b>$MSG_STOP_TITLE</b> <i>($timestamp)</i>"
      ;;
    "PermissionRequest")
      IFS='|' read -r tool description file_path command <<< "$data"

      if [ "$level" = "minimal" ]; then
        message="⚠️ <b>$MSG_PERMISSION_MINIMAL:</b> <code>$(escape_html "$tool")</code> <i>($timestamp)</i>"
      else
        message="⚠️ <b>$MSG_PERMISSION_TITLE</b> <i>($timestamp)</i>\n\n"
        message+="<b>$MSG_LABEL_TOOL:</b> <code>$(escape_html "$tool")</code>"

        if [ -n "$description" ] && [ "$description" != "null" ]; then
          description=$(truncate_text "$description" 150)
          message+="\n<b>$MSG_LABEL_ACTION:</b> $(escape_html "$description")"
        fi

        if [ -n "$file_path" ] && [ "$file_path" != "null" ]; then
          message+="\n<b>$MSG_LABEL_FILE:</b> <code>$(escape_html "$file_path")</code>"
        fi

        if [ -n "$command" ] && [ "$command" != "null" ]; then
          command=$(truncate_text "$command" 200)
          message+="\n<b>$MSG_LABEL_COMMAND:</b> <code>$(escape_html "$command")</code>"
        fi
      fi
      ;;
    *)
      message="📢 <b>$MSG_GENERIC_EVENT $(escape_html "$event")</b> <i>($timestamp)</i>"
      ;;
  esac

  echo "$message"
}

# Send message to Telegram
send_telegram_message() {
  local message="$1"
  local url="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

  # Escape quotes for JSON
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
    log_error "$MSG_ERROR_TELEGRAM_API: $response"
  fi
}

# Send notification (generic function)
send_notification() {
  local message="$1"
  local messenger="${MESSENGER:-telegram}"

  case "$messenger" in
    telegram)
      send_telegram_message "$message"
      ;;
    *)
      log_error "$MSG_ERROR_UNKNOWN_MESSENGER: $messenger"
      ;;
  esac
}

# Main logic
main() {
  # Get timestamp for logging
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Load configuration
  load_env

  # Load locale (default to English if not set)
  load_locale "${LANGUAGE:-en}"

  # Rotate log file if needed
  rotate_log_if_needed "$LOG_FILE"

  # Check if notifications are enabled
  ENABLED="${NOTIFICATIONS_ENABLED:-true}"
  if [ "$ENABLED" != "true" ]; then
    exit 0
  fi

  # Read JSON from stdin
  INPUT=$(cat)

  # Extract event name
  EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // .hookEventName // .event // "unknown"')

  # Get detail level
  LEVEL="${NOTIFICATION_LEVEL:-detailed}"

  # Format current time for messages
  local message_time
  message_time=$(date '+%d.%m.%Y %H:%M:%S')

  # Prepare event data
  local event_data
  event_data=$(prepare_event_data "$INPUT" "$EVENT")

  # Format message
  local message
  message=$(format_message "$EVENT" "$event_data" "$LEVEL" "$message_time")

  # Send notification
  send_notification "$message" 2>/dev/null || {
    log_error "$MSG_ERROR_SEND_FAILED: $message"
  }
}

# Run main and always return success to not block Claude's work
main || true
exit 0
