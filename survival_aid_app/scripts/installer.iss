; Inno Setup script for AIDEM
; This creates a professional .exe installer that hides all DLLs and installs the app properly.

[Setup]
AppId={{589A15D0-31BC-4C40-99DF-443DA4E6BA35}
AppName=AIDEM
AppVersion=1.0
DefaultDirName={autopf}\SurvivalAId
DefaultGroupName=AIDEM
OutputDir=..\dist
OutputBaseFilename=SurvivalAId_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\AIDEM"; Filename: "{app}\survival_aid_app.exe"
Name: "{autodesktop}\AIDEM"; Filename: "{app}\survival_aid_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\survival_aid_app.exe"; Description: "{cm:LaunchProgram,AIDEM}"; Flags: nowait postinstall skipifsilent
