# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-05-02

### Added
- Initial release of Claude Code Telegram Notifier
- Core notification system for Claude Code events
- Support for two hook events:
  - `Stop` - Claude Code completion notifications
  - `PermissionRequest` - Action confirmation request notifications
- Telegram messenger integration via Bot API
- Two notification detail levels:
  - `detailed` - Full information (description, files, commands)
  - `minimal` - Brief messages (event and tool only)
- Multi-language support system:
  - English (en) locale
  - Russian (ru) locale
  - Easy extensibility for additional languages
- Configuration management:
  - `.env` file for settings
  - `.env.sample` template with detailed comments
  - `notify-toggle` utility for quick enable/disable
- Smart path handling:
  - Absolute paths converted to relative
  - Paths outside project show filename only
  - Symlink resolution support
- Log rotation system:
  - Configurable maximum log file size (default: 1 MB)
  - Configurable number of rotated files to keep (default: 2)
  - Automatic cleanup of old log files
- Event deduplication mechanism:
  - 5-second deduplication window
  - Prevents duplicate notifications from multiple hook triggers
  - Automatic cleanup of old deduplication data
- Security features:
  - HTML escaping for Telegram messages
  - Command text truncation (200 characters)
  - Description truncation (150 characters)
  - Script always exits with 0 to never block Claude's workflow
- Testing utilities:
  - `test-notifications.sh` - Comprehensive test suite
  - Direct hook testing support
  - Log monitoring capabilities
- Documentation:
  - Comprehensive README in English and Russian
  - CLAUDE.md with developer instructions
  - Extension guide for adding new messengers (docs/adding-messengers.md)
  - Inline code comments for complex logic
- Project configuration:
  - `.claude/settings.json` with pre-configured hooks
  - `.gitignore` with proper exclusions
  - Cross-platform compatibility (macOS, Linux, Windows with WSL)

### Technical Details
- Written in Bash 4.0+ for maximum compatibility
- Dependencies: `curl`, `jq`
- Total codebase: ~586 lines of shell script
- Supports both local and global Claude Code hook installation
- Async hook execution for PermissionRequest events
- 10-second timeout for API requests
- User-Agent header for API identification

### Infrastructure
- Git repository with clean history
- Proper .gitignore configuration
- No secrets in version control
- IDE configuration excluded (.idea/)

[Unreleased]: https://github.com/yourusername/claude-notifier/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/claude-notifier/releases/tag/v1.0.0
