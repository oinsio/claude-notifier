#!/usr/bin/env bash
# Hook для отправки уведомлений в Telegram при событиях Claude Code

# Путь к скрипту notifier (относительно этого hook)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NOTIFIER="$SCRIPT_DIR/notify.py"

# Проверка существования скрипта
if [ ! -f "$NOTIFIER" ]; then
  echo "Error: notify.py not found at $NOTIFIER" >&2
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
python3 "$NOTIFIER" "$MESSAGE" 2>/dev/null || true

# Всегда возвращаем успех, чтобы не блокировать работу Claude
exit 0
