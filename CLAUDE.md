# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Setup

```bash
cp .env.sample .env  # Edit with Telegram credentials
chmod +x notify-hook.sh notify-toggle test-notifications.sh
```

## Testing

```bash
./test-notifications.sh                              # Full test suite
echo '{"hook_event_name":"Stop"}' | ./notify-hook.sh  # Test specific event
tail -f notify.log                                   # Check logs
```

## Localization

New language: create `locales/XX.sh` (copy `locales/en.sh` structure), translate all `MSG_*` variables, set `LANGUAGE=XX` in `.env`.

## Gotchas

- Script resolves symlinks to find its location — supports symlinked installations
- Script always exits 0 to never block Claude's workflow
- Absolute paths converted to relative in messages; paths outside project show filename only
- Script automatically rotates log files to prevent unlimited growth

## Extending

To add messenger support (Slack, Discord, etc.), see @docs/adding-messengers.md
