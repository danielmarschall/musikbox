program Musikbox;

{$Description 'ViaThinkSoft MusikBox 1.5'}

uses
  Forms,
  Windows,
  Dialogs,
  Main in 'Main.pas' {MainForm},
  Info in 'Info.pas' {InfoForm},
  Config in 'Config.pas' {ConfigForm};

{$R *.res}

var
  mHandle: THandle;

begin
  mHandle := CreateMutex(Nil, True, 'ViaThinkSoft MusikBox');
  if GetLastError = ERROR_ALREADY_EXISTS then
    ShowMessage('Programm läuft bereits!');
  if mHandle <> 0 Then
    CloseHandle(mHandle);

  Application.Initialize;
  Application.Title := 'ViaThinkSoft MusikBox';
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TInfoForm, InfoForm);
  Application.CreateForm(TConfigForm, ConfigForm);
  Application.Run;
end.
