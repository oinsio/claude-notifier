# Telegram Notifier

Минимальный Python-скрипт для отправки уведомлений в Telegram без внешних зависимостей.

## Установка

1. Создайте `.env` файл на основе `.env.example`:
```bash
cp .env.example .env
```

2. Получите токен бота:
   - Напишите @BotFather в Telegram
   - Создайте нового бота командой `/newbot`
   - Скопируйте токен

3. Получите Chat ID:
   - Напишите @userinfobot в Telegram
   - Скопируйте ваш ID

4. Заполните `.env`:
```
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
```

## Использование

```bash
# Отправить простое сообщение
python3 notify.py "Привет из скрипта!"

# Отправить многострочное сообщение
python3 notify.py "Первая строка" "Вторая строка"

# Сделать исполняемым (опционально)
chmod +x notify.py
./notify.py "Тестовое сообщение"
```

## Логирование

Ошибки записываются в файл `notify.log` в той же директории.

## Требования

- Python 3.6+
- Только стандартная библиотека (urllib, json, pathlib)
