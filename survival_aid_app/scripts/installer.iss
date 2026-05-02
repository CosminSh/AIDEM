; Inno Setup script for Survival AId
; This creates a professional .exe installer that hides all DLLs and installs the app properly.

[Setup]
AppId={{589A15D0-31BC-4C40-99DF-443DA4E6BA35}
AppName=Survival AId
AppVersion=1.0
DefaultDirName={autopf}\SurvivalAId
DefaultGroupName=Survival AId
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
Name: "{group}\Survival AId"; Filename: "{app}\survival_aid_app.exe"
Name: "{autodesktop}\Survival AId"; Filename: "{app}\survival_aid_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\survival_aid_app.exe"; Description: "{cm:LaunchProgram,Survival AId}"; Flags: nowait postinstall skipifsilent
