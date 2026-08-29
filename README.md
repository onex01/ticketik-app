# Тикетик — Система заявок в техподдержку

Приложение для быстрой отправки заявок в техническую поддержку.

## Возможности

- 🚀 Быстрая отправка заявки
- 📋 История заявок пользователя
- 🔐 Скрытая админ-панель (двойной тап по логотипу + PIN: 410022)
- 🌓 Переключение темы (светлая/тёмная/системная)
- 💾 Мягкое удаление заявок (архивирование)
- 🖥️ Определение устройства и IP-адреса
- 📦 Linux-пакеты (.deb и .rpm)

## Установка

### Windows
Запустите `Ticketik_Setup.exe` из папки `output/`.

### Linux

#### Debian/Ubuntu
```bash
sudo apt install ./ticketik_0.1.0_amd64.deb
```

#### RHEL/CentOS/Fedora
```bash
sudo rpm -i ticketik-0.1.0.x86_64.rpm
```

## Сборка

### Требования
- Flutter SDK 3.13+
- Firebase проект с настроенным Firestore

### Установка зависимостей
```bash
flutter pub get
```

### Сборка Linux пакетов
```bash
# DEB пакет
flutter_distributor package --platform linux --target deb

# RPM пакет
flutter_distributor package --platform linux --target rpm
```

### Сборка Windows
```bash
flutter build windows
```

## Структура базы данных

### Коллекция `devices`
- `ip` (string) — IP-адрес устройства
- `room` (string) — Кабинет
- `pc_number` (string) — Номер ПК
- `owner` (string) — Сотрудник

### Коллекция `requests`
- `device_id` (string) — ID устройства
- `device_ip` (string) — IP-адрес
- `description` (string) — Описание проблемы
- `room` (string) — Кабинет
- `pc_number` (string) — Номер ПК
- `owner` (string) — Сотрудник
- `os_name` (string) — Операционная система
- `status` (string) — Статус (new/in_progress/done)
- `timestamp` (timestamp) — Время создания
- `is_deleted` (bool) — Пометка об удалении (для админки)

## Индексы Firestore

Для работы запросов необходимо создать составной индекс:
[Ссылка на создание индекса](https://console.firebase.google.com/v1/r/project/ticketik-app/firestore/indexes?create_composite=Ck1wcm9qZWN0cy90aWNrZXRpay1hcHAvZGF0YWJhc2VzLyhkZWZhdWx0KS9jb2xsZWN0aW9uR3JvdXBzL3JlcXVlc3RzL2luZGV4ZXMvXxABGg0KCWRldmljZV9pcBABGg4KCmlzX2RlbGV0ZWQQARONCgl0aW1lc3RhbXAQAhoMCghfX25hbWVfXxAC)

Или вручную:
- Collection: `requests`
- Fields: `device_ip` (Ascending), `is_deleted` (Ascending), `timestamp` (Descending)

## Лицензия

MIT
