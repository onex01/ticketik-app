# Инструкция по сборке Linux-пакетов для Тикетик

## Требования

1. Установленный Flutter SDK (версия 3.13+)
2. Установленные зависимости для сборки Linux:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev libappindicator3-dev

   # Fedora/RHEL
   sudo dnf install -y clang cmake ninja-build pkgconfig gtk3-devel libappindicator-gtk3-devel
   ```

## Сборка .deb пакета (Debian/Ubuntu)

### Вариант 1: Ручная сборка (рекомендуется, если flutter_distributor не установлен)

```bash
cd /workspace
flutter pub get
flutter build linux --release
```

После успешной сборки бинарник будет находиться в `build/linux/x64/release/bundle/`

Для создания DEB-пакета вручную:

```bash
cd build/linux/x64/release/bundle

# Создание структуры DEB пакета
mkdir -p ticketik_DEB/DEBIAN
mkdir -p ticketik_DEB/usr/bin
mkdir -p ticketik_DEB/usr/share/applications
mkdir -p ticketik_DEB/usr/share/icons/hicolor/256x256/apps

# Копирование файлов
cp -r * ticketik_DEB/usr/bin/
cp /workspace/linux/runner/ticketik.desktop ticketik_DEB/usr/share/applications/
cp /workspace/linux/runner/app_icon.ico ticketik_DEB/usr/share/icons/hicolor/256x256/apps/ticketik.ico

# Создание control файла
cat > ticketik_DEB/DEBIAN/control << 'CONTROL'
Package: ticketik
Version: 0.8.5
Section: x11
Priority: optional
Architecture: amd64
Maintainer: Ticketik Team <support@ticketik.local>
Description: Система заявок в техподдержку
 Тикетик - приложение для быстрой отправки заявок в техническую поддержку
Depends: libgtk-3-0, libappindicator3-1
CONTROL

# Сборка DEB пакета
cd ..
dpkg-deb --build ticketik_DEB ticketik_0.8.5_amd64.deb
```

### Вариант 2: Через flutter_distributor (если установлен)

```bash
# Установка flutter_distributor (требуется Dart SDK)
dart pub global activate flutter_distributor

# Сборка
cd /workspace
flutter pub get
flutter_distributor package --platform linux --target deb
```

Пакет будет создан в директории `dist/`.

**Важно:** В пакете уже указаны необходимые зависимости:
- libgtk-3-0
- libappindicator3-1

## Сборка .rpm пакета (Fedora/RHEL/CentOS)

### Вариант 1: Ручная сборка

```bash
cd /workspace
flutter build linux --release

cd build/linux/x64/release/bundle

# Создание структуры RPM пакета
mkdir -p ticketik_RPM/BUILD
mkdir -p ticketik_RPM/SOURCES
mkdir -p ticketik_RPM/RPMS
mkdir -p ticketik_RPM/SRPMS
mkdir -p ticketik_RPM/SPECS

# Копирование файлов
cp -r * ticketik_RPM/SOURCES/

# Создание spec файла
cat > ticketik_RPM/SPECS/ticketik.spec << 'SPEC'
Name:           ticketik
Version:        0.8.5
Release:        1%{?dist}
Summary:        Система заявок в техподдержку
License:        MIT
URL:            https://ticketik.local
BuildArch:      x86_64
Requires:       gtk3 libappindicator

%description
Тикетик - приложение для быстрой отправки заявок в техническую поддержку

%install
mkdir -p %{buildroot}/usr/bin
cp -r %{_sourcedir}/* %{buildroot}/usr/bin/

%files
/usr/bin/*

%changelog
* Mon Jan 01 2024 Ticketik Team <support@ticketik.local> - 0.8.5
- Initial package
SPEC

# Сборка RPM пакета
rpmbuild -bb ticketik_RPM/SPECS/ticketik.spec --define "_topdir $(pwd)/ticketik_RPM" --define "_rpmdir $(pwd)/ticketik_RPM/RPMS"

# Готовый пакет будет в ticketik_RPM/RPMS/x86_64/
```

### Вариант 2: Через flutter_distributor

```bash
cd /workspace
flutter pub get
flutter_distributor package --platform linux --target rpm
```

Пакет будет создан в директории `dist/`.

**Важно:** В пакете уже указаны необходимые зависимости:
- gtk3
- libappindicator

## Установка готовых пакетов

### Debian/Ubuntu
```bash
sudo apt install ./ticketik_0.8.5_amd64.deb
```

### Fedora/RHEL/CentOS
```bash
sudo rpm -i ticketik-0.8.5.x86_64.rpm
```

## Запуск приложения

После установки приложение доступно:
- Через меню приложений как "Тикетик"
- Из командной строки: `ticketik`

## Решение проблем

### Ошибка: "Dart snapshot generator failed with exit code -6"

Эта ошибка может возникнуть при сборке на WSL или в некоторых окружениях. Попробуйте:

1. Очистить кэш сборки:
   ```bash
   flutter clean
   rm -rf build/
   ```

2. Обновить Flutter:
   ```bash
   flutter upgrade
   ```

3. Попробовать собрать в режиме profile вместо release:
   ```bash
   flutter build linux --profile
   ```

4. Если используете WSL, попробуйте собрать в нативной Linux-среде (VirtualBox, VM и т.д.)

### Ошибка: "flutter_distributor: command not found"

flutter_distributor требует Dart SDK. Если он не установлен:

1. Установите Dart SDK:
   ```bash
   sudo apt-get install dart
   ```

2. Или используйте ручную сборку через CMake (Вариант 1 выше)

### Ошибка: зависимости при установке

Убедитесь, что установлены все необходимые зависимости:

```bash
# Ubuntu/Debian
sudo apt-get install libgtk-3-0 libappindicator3-1

# Fedora/RHEL
sudo dnf install gtk3 libappindicator
```

## Примечания

- **Уведомления работают только на Android** — версии для Linux/Windows/macOS не поддерживают push-уведомления
- Приложение автоматически определяет IP-адрес устройства при отправке заявки
- Для работы уведомлений на Android необходимо предоставить разрешения при первом запуске
- Минимальная версия Linux: Ubuntu 18.04+ / Fedora 30+ / Debian 10+
