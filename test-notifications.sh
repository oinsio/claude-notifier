#!/usr/bin/env bash
# Test script for notification verification

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧪 Testing notifications..."
echo ""

# Test 1: PermissionRequest with Bash command
echo "1️⃣ Test: PermissionRequest (Bash)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"npm install","description":"Installing project dependencies"}}' | ./notify-hook.sh
echo "✅ Sent"
echo ""

# Test 2: PermissionRequest with Write (absolute path)
echo "2️⃣ Test: PermissionRequest (Write with absolute path)"
echo "{\"hook_event_name\":\"PermissionRequest\",\"tool_name\":\"Write\",\"cwd\":\"$SCRIPT_DIR\",\"tool_input\":{\"file_path\":\"$SCRIPT_DIR/src/config/database.yml\",\"description\":\"Creating new configuration file\"}}" | ./notify-hook.sh
echo "✅ Sent"
echo ""

# Test 3: PermissionRequest with Edit (relative path)
echo "3️⃣ Test: PermissionRequest (Edit with relative path)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Edit","tool_input":{"file_path":"src/main.ts","description":"Fixing bug in main file"}}' | ./notify-hook.sh
echo "✅ Sent"
echo ""

# Test 4: PermissionRequest with long command
echo "4️⃣ Test: PermissionRequest (long command)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"find /usr/local -type f -name '"'"'*.so'"'"' -o -name '"'"'*.dylib'"'"' | xargs ls -lh | awk '"'"'{print $5, $9}'"'"' | sort -h | tail -20 | while read size file; do echo \"File: $file, Size: $size\"; done","description":"Executing complex command with multiple parameters to test long string processing and verify correct text truncation in notification"}}' | ./notify-hook.sh
echo "✅ Sent"
echo ""

# Test 5: PermissionRequest with path outside project
echo "5️⃣ Test: PermissionRequest (file outside project)"
echo "{\"hook_event_name\":\"PermissionRequest\",\"tool_name\":\"Read\",\"cwd\":\"$SCRIPT_DIR\",\"tool_input\":{\"file_path\":\"/etc/hosts\",\"description\":\"Reading system file\"}}" | ./notify-hook.sh
echo "✅ Sent"
echo ""

# Test 6: Stop event
echo "6️⃣ Test: Stop"
echo '{"hook_event_name":"Stop","session_id":"test-session-123"}' | ./notify-hook.sh
echo "✅ Sent"
echo ""

echo "✨ All tests completed! Check Telegram."
echo ""
echo "📋 Logs:"
tail -10 notify.log
