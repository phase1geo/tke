; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{B1160ED7-B6CF-4517-BC80-7C0FE9D90212}
AppName=TKE
AppVersion=3.6
AppPublisher=Trevor Williams
AppPublisherURL=http://tke.sourceforge.net
AppSupportURL=http://tke.sourceforge.net
AppUpdatesURL=http://tke.sourceforge.net
DefaultDirName={pf}\TKE
DefaultGroupName=TKE
OutputBaseFilename=setup-tke
Compression=lzma
SolidCompression=yes
OutputDir=c:\cygwin64\home\Trevor\projects\releases

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "czech"; MessagesFile: "compiler:Languages\Czech.isl"
Name: "danish"; MessagesFile: "compiler:Languages\Danish.isl"
Name: "dutch"; MessagesFile: "compiler:Languages\Dutch.isl"
Name: "french"; MessagesFile: "compiler:Languages\French.isl"
Name: "german"; MessagesFile: "compiler:Languages\German.isl"
Name: "greek"; MessagesFile: "compiler:Languages\Greek.isl"
Name: "hebrew"; MessagesFile: "compiler:Languages\Hebrew.isl"
Name: "hungarian"; MessagesFile: "compiler:Languages\Hungarian.isl"
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"
Name: "japanese"; MessagesFile: "compiler:Languages\Japanese.isl"
Name: "norwegian"; MessagesFile: "compiler:Languages\Norwegian.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"
Name: "portuguese"; MessagesFile: "compiler:Languages\Portuguese.isl"
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "C:\cygwin64\home\Trevor\projects\releases\tke.exe"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\TKE"; Filename: "{app}\tke.exe"
Name: "{commondesktop}\TKE"; Filename: "{app}\tke.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\tke.exe"; Description: "{cm:LaunchProgram,TKE}"; Flags: nowait postinstall skipifsilent

