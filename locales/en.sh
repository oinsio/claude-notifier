#!/usr/bin/env bash
# English locale for Claude Code notifications

# Stop event messages
MSG_STOP_TITLE="Claude Code has finished"

# PermissionRequest event messages
MSG_PERMISSION_TITLE="Permission required"
MSG_PERMISSION_MINIMAL="Permission required"

# Field labels
MSG_LABEL_TOOL="Tool"
MSG_LABEL_ACTION="Action"
MSG_LABEL_FILE="File"
MSG_LABEL_COMMAND="Command"

# Generic event message
MSG_GENERIC_EVENT="Claude Code: event"

# Error messages
MSG_ERROR_ENV_NOT_FOUND="Error: .env file not found at"
MSG_ERROR_TOKEN_REQUIRED="Error: TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in .env"
MSG_ERROR_TELEGRAM_API="Telegram API error"
MSG_ERROR_UNKNOWN_MESSENGER="Unknown messenger"
MSG_ERROR_SEND_FAILED="Failed to send message"

# notify-toggle messages
MSG_TOGGLE_ENV_NOT_FOUND="❌ .env file not found:"
MSG_TOGGLE_ENABLED="✅ Notifications enabled"
MSG_TOGGLE_DISABLED="🔕 Notifications disabled"
MSG_TOGGLE_STATUS_ENABLED="✅ Notifications: enabled"
MSG_TOGGLE_STATUS_DISABLED="🔕 Notifications: disabled"
MSG_TOGGLE_USAGE="Usage: notify-toggle [on|off]"
MSG_TOGGLE_USAGE_ON="  on  - enable notifications"
MSG_TOGGLE_USAGE_OFF="  off - disable notifications"
MSG_TOGGLE_USAGE_STATUS="  (no arguments) - show current status"
