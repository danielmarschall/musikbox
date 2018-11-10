{=====================================================|
| WaveControl 1.00 - (c) 1998 by John Mogesnen, DK    |
|-----------------------------------------------------|
| Change the WAV-Volume settings for Delphi 3         |
| (16 and 32 bits)                                    |
|-----------------------------------------------------|
| E-Mail:    JMogensnen@Web4you.dk                    |
|=====================================================}
(* Attention: To enabled componentuser to change the
              Update time remove the {} from the Code!*)

unit WaveControl;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, ComCtrls;

type
  TWaveVolumeSetting = class(TTrackBar)
  private
     FTimer : TTimer;
     FInterval : Integer;

{     procedure SetInterval(Value : integer);}
     procedure FTimerOnTimer(sender:TObject);
     procedure OnTrackChange(Sender : TObject);
     function GetTrackBar : integer;
     procedure SetVolume;
  protected
  public
     constructor Create (AOwner : TComponent); override;
     destructor Destroy; override;
  published
{     property WavUpdateInterval: integer read FInterval write SetInterval;}
  end;

procedure Register;

var
  pCurrentVolumeLevel: PDWord;
  CurrentVolumeLevel: DWord;
  VolumeControlHandle: hWnd;
  GetCurrentVolumeLevel: LPDWORD;

implementation

Uses Wave_System_Control;

procedure Register;
begin
  RegisterComponents('Samples', [TWaveVolumeSetting]);
end;


constructor TWaveVolumeSetting.Create (AOwner : TComponent);
begin
 inherited Create(Aowner);
 New(pCurrentVolumeLevel);
   Orientation := trVertical;
   TickStyle := tsNone;
   TickMarks := tmBoth;
   Width := 27;
   Height := 113;
   min := 0;
   max := 26;

   FInterval := 1;
   FTimer := TTimer.create(self);
   FTimer.Enabled := TRUE;
   FTimer.interval := FInterval;
   FTimer.OnTimer  := FTimerOnTimer;
   OnChange := OnTrackChange;
   SetVolume;
end;


destructor TWaveVolumeSetting.Destroy;
begin
  inherited Destroy;
end;

{
procedure TWaveVolumeSetting.SetInterval(Value: integer);
begin
  if (FInterval <> Value) then
  begin
    FInterval := Value;
    FTimer.interval := FInterval;
  end;
end;
}

function TWaveVolumeSetting.GetTrackBar: integer;
begin
  result := 65535 div max;
end;


procedure TWaveVolumeSetting.OnTrackChange(Sender : TObject);
Var
  x : Integer;

begin
  IF Orientation=trVertical then
     x := max - position
     ELSE
     x := position;

  CurrentVolumeLevel := (x * GetTrackBar shl 16) + (x * GetTrackBar);
  WaveOutSetVolume(VolumeControlHandle, CurrentVolumeLevel);
end;


procedure TWaveVolumeSetting.SetVolume;
begin
  VolumeControlHandle := FindWindow('Volume Control', nil);
  WaveOutGetVolume(VolumeControlHandle, pCurrentVolumeLevel);
  CurrentVolumeLevel := pCurrentVolumeLevel^;

  IF Orientation=trVertical then
     position := max - LoWord(CurrentVolumeLevel) DIV GetTrackBar
     ELSE
     position := LoWord(CurrentVolumeLevel) DIV GetTrackBar;
end;


procedure TWaveVolumeSetting.FTimerOnTimer(sender:TObject);
begin
  SetVolume;
end;

end.
