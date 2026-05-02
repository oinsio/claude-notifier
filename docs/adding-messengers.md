# Adding New Messenger Integrations

The project supports multiple messengers via the `MESSENGER` env variable. Currently only Telegram is implemented.

## Implementation Pattern

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

## Key Considerations

- Each messenger has different message formatting (Telegram uses HTML, Slack uses mrkdwn, Discord uses markdown)
- API rate limits vary by messenger
- Authentication methods differ (bot tokens, webhooks, OAuth)
- Message length limits differ
- Consider creating separate formatting functions for each messenger if markup differs significantly
