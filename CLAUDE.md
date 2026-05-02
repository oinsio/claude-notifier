# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Telegram notification system for Claude Code events. Sends notifications to Telegram when Claude finishes work or requests permissions. Supports multiple languages (English/Russian) and configurable notification levels.

## Architecture

**Core Components:**
- `notify-hook.sh` - Main hook script that processes Claude Code events and sends notifications
- `notify-toggle` - Utility to enable/disable notifications without editing .env
- `test-notifications.sh` - Test suite for verifying notification delivery
- `locales/` - Localization files (en.sh, ru.sh) containing all user-facing messages
- `.env` - Configuration file (not in git, created from .env.sample)

**Hook Integration:**
- Configured in `.claude/settings.json` for project-level hooks
- Listens to two events: `Stop` (Claude finishes) and `PermissionRequest` (permission needed)
- `PermissionRequest` runs async to avoid blocking Claude's workflow

**Message Flow:**
1. Claude Code triggers hook → passes JSON via stdin
2. `notify-hook.sh` parses JSON → extracts event data (tool, description, file path, command)
3. Script loads locale → formats message with HTML markup
4. Sends to Telegram API → logs errors to notify.log

**Key Functions in notify-hook.sh:**
- `prepare_event_data()` - Extracts and normalizes data from Claude's JSON
- `format_message()` - Creates HTML-formatted Telegram message
- `make_relative_path()` - Converts absolute paths to relative for cleaner messages
- `send_telegram_message()` - Handles Telegram API communication

## Configuration

**Environment Variables (.env):**
```bash
TELEGRAM_BOT_TOKEN=...        # From @BotFather
TELEGRAM_CHAT_ID=...          # From @userinfobot
NOTIFICATIONS_ENABLED=true    # Toggle notifications
NOTIFICATION_LEVEL=detailed   # detailed|minimal
MESSENGER=telegram            # Future: slack, discord
LANGUAGE=en                   # en|ru
```

**Notification Levels:**
- `detailed` - Full info (tool, description, file path, command)
- `minimal` - Brief (tool name only)

## Common Commands

**Setup:**
```bash
# Initial setup
cp .env.sample .env
# Edit .env with your Telegram credentials
chmod +x notify-hook.sh notify-toggle test-notifications.sh
```

**Testing:**
```bash
# Run full test suite
./test-notifications.sh

# Test specific event
echo '{"hook_event_name":"Stop"}' | ./notify-hook.sh

# Check logs
tail -f notify.log
```

**Toggle Notifications:**
```bash
./notify-toggle          # Show status
./notify-toggle on       # Enable
./notify-toggle off      # Disable
```

## Localization

**Adding New Language:**
1. Create `locales/XX.sh` (copy structure from `locales/en.sh`)
2. Translate all `MSG_*` variables
3. Set `LANGUAGE=XX` in .env

**Message Variables:**
- `MSG_STOP_TITLE` - Stop event title
- `MSG_PERMISSION_TITLE` - Permission request title
- `MSG_LABEL_*` - Field labels (Tool, Action, File, Command)
- `MSG_ERROR_*` - Error messages
- `MSG_TOGGLE_*` - notify-toggle script messages

## Important Implementation Details

**Path Handling:**
- Script resolves symlinks to find its real location (supports symlinked installations)
- Absolute paths are converted to relative paths for cleaner messages
- Paths outside project show only filename

**Error Handling:**
- All errors logged to `notify.log` with timestamps
- Script always exits with 0 to never block Claude's workflow
- Failed API calls are logged but don't interrupt execution

**JSON Parsing:**
- Uses `jq` for robust JSON parsing
- Handles multiple field name variations (snake_case, camelCase)
- Gracefully handles missing fields with fallbacks

**Security:**
- HTML special characters are escaped to prevent injection
- Long commands/descriptions are truncated (200/150 chars)
- Bot token and chat ID stored in .env (gitignored)

## Hook Configuration

**Project-level** (already configured in `.claude/settings.json`):
- Works only in this directory
- Relative path: `./notify-hook.sh`

**Global setup** (for all projects):
- Add to `~/.claude/settings.json`
- Must use absolute path: `/full/path/to/notify-hook.sh`
- Requires Claude Code restart after changes

## Dependencies

- Bash 4.0+
- `curl` - HTTP requests to Telegram API
- `jq` - JSON parsing (install: `brew install jq` on macOS)

## Adding New Messenger Integrations

The project is designed to support multiple messengers. Currently only Telegram is implemented, but the architecture allows easy addition of new messengers.

**Implementation Pattern:**

1. **Add messenger-specific function** in `notify-hook.sh`:
   ```bash
   send_slack_message() {
     local message="$1"
     # Slack API implementation
   }

   send_discord_message() {
     local message="$1"
     # Discord webhook implementation
   }
   ```

2. **Update `send_notification()` function** to route to new messenger:
   ```bash
   case "$messenger" in
     telegram) send_telegram_message "$message" ;;
     slack) send_slack_message "$message" ;;
     discord) send_discord_message "$message" ;;
     *) log_error "$MSG_ERROR_UNKNOWN_MESSENGER: $messenger" ;;
   esac
   ```

3. **Add configuration variables** to `.env.sample`:
   ```bash
   # For Slack
   SLACK_WEBHOOK_URL=...

   # For Discord
   DISCORD_WEBHOOK_URL=...
   ```

4. **Update `load_env()` function** to read new variables

5. **Add test cases** to `test-notifications.sh` for new messenger

**Key Considerations:**
- Each messenger has different message formatting (Telegram uses HTML, Slack uses mrkdwn, Discord uses markdown)
- API rate limits vary by messenger
- Authentication methods differ (bot tokens, webhooks, OAuth)
- Message length limits differ
- Consider creating separate formatting functions for each messenger if markup differs significantly

## Bilingual Documentation

- `README.md` - English documentation (primary)
- `README.ru.md` - Russian documentation
- Both contain language switcher badges
