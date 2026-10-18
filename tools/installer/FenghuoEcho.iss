#ifndef PayloadDir
  #error PayloadDir must point to the prepared player payload.
#endif
#ifndef OutputDir
  #error OutputDir is required.
#endif
#ifndef GameVersion
  #error GameVersion is required.
#endif
#ifndef ChineseLanguage
  #error ChineseLanguage must point to ChineseSimplified.isl.
#endif

[Setup]
AppId={{D72EA144-21F6-454B-A70D-DB2BED768092}
AppName=烽火回声 · 林海归途
AppVersion={#GameVersion}
AppVerName=烽火回声 · 林海归途 {#GameVersion}
AppPublisher=烽火回声项目
AppPublisherURL=https://github.com/zhaichaofan3/DongBeiKangLian
AppSupportURL=https://github.com/zhaichaofan3/DongBeiKangLian/issues
AppUpdatesURL=https://github.com/zhaichaofan3/DongBeiKangLian/releases
DefaultDirName={localappdata}\Programs\FenghuoEcho
DefaultGroupName=烽火回声 · 林海归途
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir={#OutputDir}
OutputBaseFilename=FenghuoEcho-{#GameVersion}-Setup-Windows-x64
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern
WizardResizable=no
DisableWelcomePage=no
UninstallDisplayIcon={app}\FenghuoEcho.exe
UninstallDisplayName=烽火回声 · 林海归途
CloseApplications=yes
RestartApplications=no
SetupLogging=yes
InfoBeforeFile={#PayloadDir}\INSTALL.txt

[Languages]
Name: "chinesesimp"; MessagesFile: "{#ChineseLanguage}"

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "快捷方式："; Flags: unchecked

[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\烽火回声 · 林海归途"; Filename: "{app}\FenghuoEcho.exe"; WorkingDir: "{app}"
Name: "{group}\游戏说明"; Filename: "{app}\README.txt"
Name: "{group}\卸载游戏"; Filename: "{uninstallexe}"
Name: "{autodesktop}\烽火回声 · 林海归途"; Filename: "{app}\FenghuoEcho.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\README.txt"; Description: "阅读游戏说明"; Flags: postinstall shellexec skipifsilent unchecked
Filename: "{app}\FenghuoEcho.exe"; Description: "启动烽火回声 · 林海归途"; WorkingDir: "{app}"; Flags: postinstall nowait skipifsilent
