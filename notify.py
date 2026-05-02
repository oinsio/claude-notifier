#!/usr/bin/env python3
"""
Минимальный Telegram notifier без внешних зависимостей.
Использует только стандартную библиотеку Python.
"""

import sys
import json
import urllib.request
import urllib.error
from pathlib import Path
from datetime import datetime


def load_env():
    """Загружает переменные из .env файла."""
    env_path = Path(__file__).parent / '.env'
    config = {}

    if not env_path.exists():
        return config

    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, _, value = line.partition('=')
                config[key.strip()] = value.strip().strip('"').strip("'")

    return config


def log_error(message):
    """Записывает ошибку в лог файл."""
    log_path = Path(__file__).parent / 'notify.log'
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    with open(log_path, 'a', encoding='utf-8') as f:
        f.write(f"[{timestamp}] {message}\n")


def send_telegram_message(bot_token, chat_id, message):
    """Отправляет сообщение через Telegram Bot API."""
    url = f"https://api.telegram.org/bot{bot_token}/sendMessage"

    data = json.dumps({
        'chat_id': chat_id,
        'text': message,
        'parse_mode': 'HTML'
    }).encode('utf-8')

    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Python-Telegram-Notifier/1.0'
    }

    req = urllib.request.Request(url, data=data, headers=headers, method='POST')

    with urllib.request.urlopen(req, timeout=10) as response:
        result = json.loads(response.read().decode('utf-8'))
        if not result.get('ok'):
            raise Exception(f"Telegram API error: {result}")


def main():
    if len(sys.argv) < 2:
        print("Usage: notify.py <message>", file=sys.stderr)
        sys.exit(1)

    message = ' '.join(sys.argv[1:])

    try:
        config = load_env()

        bot_token = config.get('TELEGRAM_BOT_TOKEN')
        chat_id = config.get('TELEGRAM_CHAT_ID')

        if not bot_token or not chat_id:
            raise ValueError("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID must be set in .env")

        send_telegram_message(bot_token, chat_id, message)

    except Exception as e:
        error_msg = f"Error: {type(e).__name__}: {str(e)}"
        log_error(error_msg)
        print(error_msg, file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
