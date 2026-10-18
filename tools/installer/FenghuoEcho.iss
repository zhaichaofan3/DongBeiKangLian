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
AppId={code:ApplicationId}
AppName=东北抗联 烽火回声
AppVersion={#GameVersion}
AppVerName=东北抗联 烽火回声 {#GameVersion}
AppPublisher=烽火回声项目
AppPublisherURL=https://github.com/zhaichaofan3/DongBeiKangLian
AppSupportURL=https://github.com/zhaichaofan3/DongBeiKangLian/issues
AppUpdatesURL=https://github.com/zhaichaofan3/DongBeiKangLian/releases
DefaultDirName={localappdata}\Programs\FenghuoEcho
DefaultGroupName={code:ShortcutGroup}
UsePreviousGroup=no
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
UninstallDisplayName=东北抗联 烽火回声
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
Name: "{group}\东北抗联 烽火回声"; Filename: "{app}\FenghuoEcho.exe"; WorkingDir: "{app}"
Name: "{group}\游戏说明"; Filename: "{app}\README.txt"
Name: "{group}\卸载游戏"; Filename: "{uninstallexe}"
Name: "{autodesktop}\东北抗联 烽火回声"; Filename: "{app}\FenghuoEcho.exe"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\README.txt"; Description: "阅读游戏说明"; Flags: postinstall shellexec skipifsilent unchecked
Filename: "{app}\FenghuoEcho.exe"; Description: "启动东北抗联 烽火回声"; WorkingDir: "{app}"; Flags: postinstall nowait skipifsilent

[Code]
function VerificationInstall: Boolean;
begin
  Result := ExpandConstant('{param:DeliveryVerification|}') = 'isolated';
end;

function ApplicationId(Param: String): String;
begin
  if VerificationInstall then
    Result := '{2A8680CD-4EBD-4E71-BB8C-D52487A4CB27}'
  else
    Result := '{D72EA144-21F6-454B-A70D-DB2BED768092}';
end;

function ShortcutGroup(Param: String): String;
begin
  Result := '东北抗联 烽火回声';
  if VerificationInstall then Result := Result + ' QA';
end;

function InitializeSetup: Boolean;
begin
  Result := True;
  // Verification must use an explicit location, never a player's install folder.
  if VerificationInstall and (ExpandConstant('{param:DIR|}') = '') then
    Result := False;
end;
