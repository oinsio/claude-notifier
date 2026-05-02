#!/usr/bin/env bash
# Тестовый скрипт для проверки уведомлений

set -euo pipefail

echo "🧪 Тестирование уведомлений..."
echo ""

# Тест 1: PermissionRequest с Bash командой
echo "1️⃣ Тест: PermissionRequest (Bash)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"npm install","description":"Установка зависимостей проекта"}}' | ./notify-hook.sh
echo "✅ Отправлено"
echo ""

# Тест 2: PermissionRequest с Write
echo "2️⃣ Тест: PermissionRequest (Write)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Write","tool_input":{"file_path":"src/config/database.yml","description":"Создание нового файла конфигурации"}}' | ./notify-hook.sh
echo "✅ Отправлено"
echo ""

# Тест 3: PermissionRequest с Edit
echo "3️⃣ Тест: PermissionRequest (Edit)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Edit","tool_input":{"file_path":"src/main.ts","description":"Исправление бага в основном файле"}}' | ./notify-hook.sh
echo "✅ Отправлено"
echo ""

# Тест 4: PermissionRequest с длинной командой
echo "4️⃣ Тест: PermissionRequest (длинная команда)"
echo '{"hook_event_name":"PermissionRequest","tool_name":"Bash","tool_input":{"command":"find /usr/local -type f -name '"'"'*.so'"'"' -o -name '"'"'*.dylib'"'"' | xargs ls -lh | awk '"'"'{print $5, $9}'"'"' | sort -h | tail -20 | while read size file; do echo \"File: $file, Size: $size\"; done","description":"Выполняем сложную команду с множеством параметров для тестирования системы обработки длинных строк и проверки корректности обрезки текста в уведомлении"}}' | ./notify-hook.sh
echo "✅ Отправлено"
echo ""

# Тест 5: Stop событие
echo "5️⃣ Тест: Stop"
echo '{"hook_event_name":"Stop","session_id":"test-session-123"}' | ./notify-hook.sh
echo "✅ Отправлено"
echo ""

echo "✨ Все тесты завершены! Проверьте Telegram."
echo ""
echo "📋 Логи:"
tail -10 notify.log
