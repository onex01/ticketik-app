# Инструкция по сборке Linux-пакетов для Тикетик

## Требования

1. Установленный Flutter SDK (версия 3.13+)
2. Установленные зависимости для сборки Linux:
   ```bash
   # Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev
   
   # Fedora/RHEL
   sudo dnf install -y clang cmake ninja-build pkgconfig gtk3-devel
   ```

3. Установленный flutter_distributor:
   ```bash
   dart pub global activate flutter_distributor
   ```

## Сборка .deb пакета (Debian/Ubuntu)

```bash
cd /workspace
flutter pub get
flutter_distributor package --platform linux --target deb
```

Пакет будет создан в директории `dist/`.

## Сборка .rpm пакета (Fedora/RHEL/CentOS)

```bash
cd /workspace
flutter pub get
flutter_distributor package --platform linux --target rpm
```

Пакет будет создан в директории `dist/`.

## Ручная сборка через CMake

Если flutter_distributor не работает, можно собрать вручную:

```bash
cd /workspace
flutter build linux

# Создание DEB пакета вручную
cd build/linux/x64/release/bundle
cp -r ticketik_app /tmp/ticketik_app
cd /tmp

# Создание структуры DEB пакета
mkdir -p ticketik_DEB/DEBIAN
mkdir -p ticketik_DEB/usr/bin
mkdir -p ticketik_DEB/usr/share/applications
mkdir -p ticketik_DEB/usr/share/icons/hicolor/256x256/apps

# Копирование файлов
cp -r /tmp/ticketik_app/* ticketik_DEB/usr/bin/
cp /workspace/linux/runner/ticketik.desktop ticketik_DEB/usr/share/applications/
cp /workspace/linux/runner/app_icon.ico ticketik_DEB/usr/share/icons/hicolor/256x256/apps/ticketik.ico

# Создание control файла
cat > ticketik_DEB/DEBIAN/control << 'CONTROL'
Package: ticketik
Version: 0.1.0
Section: x11
Priority: optional
Architecture: amd64
Maintainer: Ticketik Team <support@ticketik.local>
Description: Система заявок в техподдержку
 Тикетик - приложение для быстрой отправки заявок в техническую поддержку
DEPENDS: libgtk-3-0
CONTROL

# Сборка DEB пакета
dpkg-deb --build ticketik_DEB ticketik_0.1.0_amd64.deb
```

## Установка готовых пакетов

### Debian/Ubuntu
```bash
sudo apt install ./ticketik_0.1.0_amd64.deb
```

### Fedora/RHEL/CentOS
```bash
sudo rpm -i ticketik-0.1.0.x86_64.rpm
```

## Запуск приложения

После установки приложение доступно:
- Через меню приложений как "Тикетик"
- Из командной строки: `ticketik_app`
