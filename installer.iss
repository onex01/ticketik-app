[Setup]
AppName=Тикетик
AppVersion=0.1.0
AppPublisher=МАОУ «СОШ» №16
DefaultDirName={autopf}\Ticketik
DefaultGroupName=Тикетик
OutputDir=output
OutputBaseFilename=Ticketik_Setup
Compression=lzma2
SolidCompression=yes
LicenseFile=license.txt
PrivilegesRequired=lowest
ArchitecturesAllowed=x64

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Files]
Source: "build\windows\x64\runner\Release\Ticketik.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Тикетик"; Filename: "{app}\Ticketik.exe"
Name: "{userdesktop}\Тикетик"; Filename: "{app}\Ticketik.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительные ярлыки:"

[Run]
Filename: "{app}\Ticketik.exe"; Description: "Запустить Тикетик"; Flags: nowait postinstall skipifsilent