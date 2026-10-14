#define Raiz "..\..\build"

[Setup]
AppId={{A3C1F7D2-5B8E-4E61-9C2A-LEGALYOU0001}
AppName=Legalização
AppVersion=1.0
AppPublisher=You Contabilidade
DefaultDirName={localappdata}\Programs\Legalizacao
DefaultGroupName=Legalização
DisableProgramGroupPage=yes
DisableDirPage=yes
PrivilegesRequired=lowest
CloseApplications=no
RestartApplications=no
OutputDir={#Raiz}\instalador
OutputBaseFilename=Legalizacao-Instalador
SetupIconFile=..\..\app\src\main\resources\icone\fiscal.ico
UninstallDisplayIcon={app}\Legalizacao.exe
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "pt"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "{#Raiz}\imagem\Legalizacao\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#Raiz}\jcef\*"; DestDir: "{%USERPROFILE}\.fiscal-jcef"; Flags: onlyifdoesntexist recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\Legalização"; Filename: "{app}\Legalizacao.exe"
Name: "{autodesktop}\Legalização"; Filename: "{app}\Legalizacao.exe"

[Run]
Filename: "{app}\Legalizacao.exe"; Description: "Abrir a Legalização"; Flags: nowait postinstall
