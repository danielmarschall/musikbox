; (De)Coder Script f�r InnoSetup
; Fehler bei Uninstallation: ReadOnly, Anwendung in Benutzung

[Setup]
AppName=MusikBox
AppVerName=MusikBox
AppVersion=1.5
AppCopyright=� Copyright 2005 - 2007 ViaThinkSoft.
AppPublisher=ViaThinkSoft
AppPublisherURL=http://www.viathinksoft.de/
AppSupportURL=http://www.daniel-marschall.de/
AppUpdatesURL=http://www.viathinksoft.de/
DefaultDirName={pf}\MusikBox 1.5
DefaultGroupName=MusikBox 1.5
UninstallDisplayIcon={app}\MusikBox.exe
VersionInfoCompany=ViaThinkSoft
VersionInfoCopyright=� Copyright 2005 - 2007 ViaThinkSoft.
VersionInfoDescription=MusikBox 1.5 Setup
VersionInfoTextVersion=1.0.0.0
VersionInfoVersion=1.5
OutputBaseFilename=MusikBoxSetup
Compression=zip/9

[Languages]
Name: de; MessagesFile: "compiler:Languages\German.isl"

[Files]
; Allgemein
Source: "MusikBox.exe"; DestDir: "{app}"
Source: "Readme.txt"; DestDir: "{app}"; Flags: isreadme

[Folders]
Name: "{group}\Webseiten"; Languages: de

[Icons]
; Allgemein
Name: "{group}\MusikBox"; Filename: "{app}\MusikBox.exe"
; Deutsch
Name: "{group}\Lies mich"; Filename: "{app}\Readme.txt"
Name: "{group}\Deinstallieren"; Filename: "{uninstallexe}"
Name: "{group}\Webseiten\Daniel Marschall"; Filename: "https://www.daniel-marschall.de/"
Name: "{group}\Webseiten\ViaThinkSoft"; Filename: "https://www.viathinksoft.de/"
Name: "{group}\Webseiten\Projektseite auf ViaThinkSoft"; Filename: "https://www.viathinksoft.de/projects/musikbox"

[Run]
Filename: "{app}\MusikBox.exe"; Description: "MusikBox starten"; Flags: nowait postinstall skipifsilent

[Code]
function InitializeSetup(): Boolean;
begin
  if CheckForMutexes('MusikBox15Setup')=false then
  begin
    Createmutex('MusikBox15Setup');
    Result := true;
  end
  else
  begin
    Result := False;
  end;
end;

