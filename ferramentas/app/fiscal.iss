#define Raiz "..\..\build"

[Setup]
AppId={{6E2B6E61-4F5C-4C1E-9F57-FISCALYOU001}
AppName=Fiscal
AppVersion=1.0
AppPublisher=You Contabilidade
DefaultDirName={localappdata}\Programs\Fiscal
DefaultGroupName=Fiscal
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
OutputDir={#Raiz}\instalador
OutputBaseFilename=Fiscal-Instalador
SetupIconFile=..\..\app\src\main\resources\icone\fiscal.ico
UninstallDisplayIcon={app}\Fiscal.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "{#Raiz}\imagem\Fiscal\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Raiz}\jcef\*"; DestDir: "{%USERPROFILE}\.fiscal-jcef"; Flags: onlyifdoesntexist recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Fiscal"; Filename: "{app}\Fiscal.exe"
Name: "{autodesktop}\Fiscal"; Filename: "{app}\Fiscal.exe"

[Run]
Filename: "{app}\Fiscal.exe"; Description: "Abrir o Fiscal"; Flags: nowait postinstall
