# Telegram Notifier for Claude Code

[![en](https://img.shields.io/badge/lang-en-blue.svg)](README.md)
[![ru](https://img.shields.io/badge/lang-ru-red.svg)](README.ru.md)

Minimal bash script for sending notifications to Telegram on Claude Code events.

## Installation

1. Create `.env` file based on `.env.sample`:
```bash
cp .env.sample .env
```

2. Get bot token:
   - Message @BotFather in Telegram
   - Create a new bot with `/newbot` command
   - Copy the token

3. Get Chat ID:
   - Message @userinfobot in Telegram
   - Copy your ID

4. Fill in `.env`:
```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
NOTIFICATIONS_ENABLED=true
NOTIFICATION_LEVEL=detailed
MESSENGER=telegram
LANGUAGE=en
```

Parameters:
- `NOTIFICATION_LEVEL` - notification detail level:
  - `detailed` (default) - full information (description, files, commands)
  - `minimal` - brief messages (event and tool only)
- `MESSENGER` - messenger for sending notifications:
  - `telegram` (default) - send to Telegram
  - Future: `slack`, `discord`, and others
- `LANGUAGE` - language for notification messages:
  - `en` (default) - English messages
  - `ru` - Russian messages (Русские сообщения)

5. Make scripts executable:
```bash
chmod +x notify-hook.sh notify-toggle
```

## Requirements

- Bash 4.0+
- `curl` (usually pre-installed)
- `jq` (for JSON parsing)

Installing jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq
```

## Integration with Claude Code

### Hook Setup

1. **For current project** (already configured in `.claude/settings.json`):
   - Hooks trigger only in this directory
   - Notifications are sent when Claude finishes work and on permission requests

2. **For global setup** (all projects):

   Add to `~/.claude/settings.json`:
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

3. **Applying changes**:

   After adding or modifying hooks, you must **restart Claude Code** for changes to take effect. Configuration is loaded only at application startup.

### Hook Events

- **Stop** - Claude finishes work (including `/clear`, `/resume`)
- **PermissionRequest** - Claude requests action confirmation

### Notification Format

Notifications contain detailed information about events:

**PermissionRequest:**
- Tool name (Bash, Edit, Write, etc.)
- Action description (from `tool_input.description`)
- File path (for file operations, from `tool_input.file_path` or `tool_input.pathInProject`)
- Command text (for Bash commands, from `tool_input.command`, truncated to 200 characters)

**Stop:**
- Notification about Claude Code completion

All messages are formatted using Telegram HTML markup for better readability.

### JSON Structure from Claude Code

Claude Code passes data in format:
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

The script automatically extracts needed fields from `tool_input`.

### Testing

```bash
# Test hook directly
echo '{"hookEventName":"Stop"}' | ./notify-hook.sh

# Check logs
tail -f notify.log
```

## Notification Management

Use the `notify-toggle` script to quickly enable/disable notifications:

```bash
# Show current status
./notify-toggle

# Enable notifications
./notify-toggle on

# Disable notifications
./notify-toggle off
```

This changes the `NOTIFICATIONS_ENABLED` value in `.env` file without manual editing.

## Localization

The project supports multiple languages for notification messages. Language is configured via the `LANGUAGE` parameter in `.env` file.

### Available Languages

- `en` - English (default)
- `ru` - Russian (Русский)

### Adding New Languages

1. Create a new locale file in `locales/` directory (e.g., `locales/fr.sh`)
2. Copy the structure from `locales/en.sh`
3. Translate all message strings
4. Set `LANGUAGE=fr` in `.env` file

Example locale file structure:
```bash
#!/usr/bin/env bash
# French locale for Claude Code notifications

MSG_STOP_TITLE="Claude Code a terminé"
MSG_PERMISSION_TITLE="Permission requise"
# ... other messages
```

## Logging

Errors are written to `notify.log` file in the same directory.

### Log Rotation

The script automatically rotates log files to prevent unlimited growth:

- **Default max size**: 1 MB (configurable via `LOG_MAX_SIZE_MB` in `.env`)
- **Rotated files kept**: 2 (configurable via `LOG_KEEP_FILES`)
- **Rotation format**: `notify.log` → `notify.log.1` → `notify.log.2`
- Oldest files are automatically deleted when the limit is reached

Configuration in `.env`:
```bash
LOG_MAX_SIZE_MB=1        # Maximum log file size in MB
LOG_KEEP_FILES=2         # Number of rotated files to keep
```
