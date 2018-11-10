unit Main;

interface

uses
  Windows, Messages, Forms, SysUtils, StdCtrls, IniFiles, MPlayer,
  Gauges, ComCtrls, ImgList, Controls, Classes, ExtCtrls,
  WaveControl, registry, Dialogs, math;

type
  TStringDynArray = array of string;

  TMainForm = class(TForm)
    lblOrdner: TLabel;
    lstSongs: TListBox;
    lblSongs: TLabel;
    sbrCopyright: TStatusBar;
    btnStart: TButton;
    BtnStopp: TButton;
    btnPause: TButton;
    btnOrdner: TButton;
    lstOrdner: TTreeView;
    ImgList: TImageList;
    MediaPlayer: TMediaPlayer;
    plyTimer: TTimer;
    grpPlayMode: TGroupBox;
    chkRepeatSong: TCheckBox;
    radPlayMode1: TRadioButton;
    radPlayMode2: TRadioButton;
    radPlayMode3: TRadioButton;
    grpRunMode: TGroupBox;
    radRunMode1: TRadioButton;
    radRunMode2: TRadioButton;
    radRunMode3: TRadioButton;
    grpVolume: TGroupBox;
    lblVolume: TLabel;
    pgrVolume: TProgressBar;
    btnBeenden: TButton;
    ggeProgress: TProgressBar;
    Status1: TLabel;
    Status2: TLabel;
    VolProc: TLabel;
    procedure FormShow(Sender: TObject);
    procedure lstSongsClick(Sender: TObject);
    procedure plyTimerTimer(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure BtnStoppClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure pgrVolumeDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure lstOrdnerChange(Sender: TObject; Node: TTreeNode);
    procedure chkRepeatSongClick(Sender: TObject);
    procedure sbrCopyrightClick(Sender: TObject);
    procedure btnBeendenClick(Sender: TObject);
    procedure btnOrdnerClick(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCanResize(Sender: TObject; var NewWidth, NewHeight: Integer;
      var Resize: Boolean);
    procedure ggeProgressMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
    // VCL-Ersatz start
    volWave: TWaveVolumeSetting;
    // VCL-Ersatz ende
    ini: TIniFile;
    MusikArray, FormatArray: TStringDynArray;
    ExtentionsArray: array of string;
    ActualPath: string;
    Playing: boolean;
    ActualVolume: integer;
    procedure ListeOrdner(ArrayElement: integer; zusatz: string; node: TTreeNode);
    procedure InitDirectories();
    procedure SchreibeEinstellung();
    procedure NextSong();
    function MCIExtensions(): string;
  end;

var
  MainForm: TMainForm;

implementation

uses Info, Config;

{$R *.dfm}

{$R windowsxp.res}

// http://www.delphipraxis.net/post592358.html
function IsFileDRMProtected(AFileName: String): Boolean;
var lCheckProc: function(const AFileName: PWideChar; var AIsProtected: Bool): HRESULT; stdcall;
    lLibHandle: Cardinal; 
    lWideChar   : PWideChar; 
    lRes        : HRESULT;
    lIsProtected: Bool;
begin 
  lLibHandle := LoadLibrary('wmvcore.dll'); 
  if (lLibHandle > 0) then
  begin
    lCheckProc := GetProcAddress(lLibHandle, 'WMIsContentProtected'); 
    if Assigned(lCheckProc) then 
    begin
      GetMem(lWideChar, MAX_PATH * SizeOf(WideChar));
      StringToWideChar(AFileName, lWideChar, MAX_PATH); 
      lRes := lCheckProc(lWideChar, lIsProtected); 
      case lRes of
        S_OK: result := lIsProtected
        else result := False; 
      end; 
    end 
    else
      result := False;
  end
  else
    result := False;
end;

// http://www.luckie-online.de/Delphi/Sonstiges/Explode.html
function Explode(const Separator, S: string; Limit: Integer = 0):
  TStringDynArray;
var
  SepLen       : Integer;
  F, P         : PChar;
  ALen, Index  : Integer;
begin
  SetLength(Result, 0);
  if (S = '') or (Limit < 0) then
    Exit;
  if Separator = '' then
  begin
    SetLength(Result, 1);
    Result[0] := S;
    Exit;
  end;
  SepLen := Length(Separator);
  ALen := Limit;
  SetLength(Result, ALen);

  Index := 0;
  P := PChar(S);
  while P^ <> #0 do
  begin
    F := P;
    P := StrPos(P, PChar(Separator));
    if (P = nil) or ((Limit > 0) and (Index = Limit - 1)) then
      P := StrEnd(F);
    if Index >= ALen then
    begin
      Inc(ALen, 5); // mehrere auf einmal um schneller arbeiten zu können
      SetLength(Result, ALen);
    end;
    SetString(Result[Index], F, P - F);
    Inc(Index);
    if P^ <> #0 then
      Inc(P, SepLen);
  end;
  if Index < ALen then
    SetLength(Result, Index); // wirkliche Länge festlegen
end;

procedure TMainForm.InitDirectories();
var
  i: integer;
  mnod: TTreeNode;
begin
  if btnStopp.Enabled then btnStopp.Click;
  btnStart.Enabled := false;
  mediaplayer.FileName := '';

  lstSongs.Items.Clear;
  lblSongs.Caption := 'Songs';

  ActualPath := '';
  lstOrdner.Items.Clear;
  for i := 0 to length(MusikArray)-1 do
  begin
    if DirectoryExists(MusikArray[i]) then
    begin
      mnod := lstOrdner.Items.Add(nil, MusikArray[i]);
      ListeOrdner(i, '', mnod);
      mnod.ImageIndex := 0;
      mnod.Expand(false);
    end;
  end;
end;

function TMainForm.MCIExtensions(): string;
var
  Reg: TRegistry;
  inifile: TIniFile;
  sl: TStringList;
  WindowsDir: string;
  WinDir: String;
  WinLen: DWord;
  i: integer;
begin
  sl := TStringList.Create();

  // Registry prüfen (ab Windows NT)
  Reg := TRegistry.Create;
  Reg.RootKey := HKEY_LOCAL_MACHINE;
  if Reg.OpenKeyReadOnly('\SOFTWARE\Microsoft\Windows NT\CurrentVersion\MCI Extensions\') then
    Reg.GetValueNames(sl)
  else
  begin
    // Win.ini, wenn Registry fehlschlägt (ab Windows 95)
    SetLength(WinDir, MAX_PATH);
    WinLen := GetWindowsDirectory(PChar(WinDir), MAX_PATH);
    if WinLen > 0 then
    begin
      SetLength(WinDir, WinLen);
      WindowsDir := WinDir;
    end
    else
      RaiseLastOSError;

    if fileexists(WindowsDir+'\win.ini') then
    begin
      inifile := TIniFile.Create(WindowsDir+'\win.ini');
      try
        if inifile.SectionExists('mci extensions') then
          inifile.ReadSection('mci extensions', sl)
        else
          if inifile.SectionExists('MCI Extensions.BAK') then
            inifile.ReadSection('MCI Extensions.BAK', sl);
      finally
        inifile.Free;
      end;
    end;
  end;
  Reg.CloseKey;
  Reg.Free;

  if sl.count = 0 then
  begin
    showmessage('Warnung! Es konnten keine MCI-Erweiterungen gefunden werden. Das Programm wird beendet.');
    close;
  end
  else
  begin
    result := '';
    for i := 0 to sl.count-1 do
      result := result + lowercase(sl.strings[i]) + '|';
    result := copy(result, 0, length(result)-1);
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  MusicPath, Formats: string;
  PlayMode, RunMode: integer;
  RepeatPlay: boolean;
begin
  // Lese INI-Einstellungen
  ini := TIniFile.Create(extractfilepath(application.ExeName)+'Settings.ini');
  try
    MusicPath := ini.ReadString('Configuration', 'Path', '');
    PlayMode := ini.ReadInteger('Configuration', 'PlayMode', 1);
    RunMode := ini.ReadInteger('Configuration', 'RunMode', 1);
    RepeatPlay := ini.ReadBool('Configuration', 'RepeatPlay', false);
    ClientWidth := ini.ReadInteger('Configuration', 'ClientWidth', ClientWidth);
    ClientHeight := ini.ReadInteger('Configuration', 'ClientHeight', ClientHeight);
  finally
    ini.Free;
  end;

  // MCI-Erweiterungen lesen
  Formats := MCIExtensions();

  // Anwenden von Einstellungen
  if PlayMode = 1 then radPlayMode1.Checked := true;
  if PlayMode = 2 then radPlayMode2.Checked := true;
  if PlayMode = 3 then radPlayMode3.Checked := true;
  if RunMode = 1 then radRunMode1.Checked := true;
  if RunMode = 2 then radRunMode2.Checked := true;
  if RunMode = 3 then radRunMode3.Checked := true;
  chkRepeatSong.Checked := RepeatPlay;
  chkRepeatSongClick(self);

  // Zerteile Verzeichnisliste
  MusikArray := Explode('|', MusicPath);
  FormatArray := Explode('|', Formats);

  InitDirectories();
end;

procedure TMainForm.ggeProgressMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (mediaplayer.FileName <> '') and (not IsFileDRMProtected(mediaplayer.filename)) then
  begin
    btnstart.Click;
    mediaplayer.Position := round(x / ggeProgress.Width * mediaplayer.length);
    mediaplayer.play;
  end;
end;

procedure TMainForm.ListeOrdner(ArrayElement: integer; zusatz: string; node: TTreeNode);
var
  SR: TSearchRec;
  RootFolder: string;
  mnod: TTreeNode;
begin
  RootFolder := MusikArray[ArrayElement]+'\'+zusatz;

  if AnsiLastChar(RootFolder)^ <> '\' then
    RootFolder := RootFolder + '\';

    if FindFirst(RootFolder + '*.*', faDirectory, SR) = 0 then
    try
      repeat
        if ((SR.Attr and faDirectory) = faDirectory) and
           (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          mnod := lstOrdner.Items.AddChild(node, SR.Name);
          ListeOrdner(ArrayElement, zusatz+SR.Name+'\', mnod);
          mnod.ImageIndex := 1;
          mnod.SelectedIndex := 1;
          mnod.Expand(false);
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
end;

procedure TMainForm.lstSongsClick(Sender: TObject);
begin
  if mediaplayer.filename <> ActualPath+lstsongs.Items.Strings[lstSongs.ItemIndex]+ExtentionsArray[lstSongs.ItemIndex] then
  begin
    mediaplayer.filename := ActualPath+lstsongs.Items.Strings[lstSongs.ItemIndex]+ExtentionsArray[lstSongs.ItemIndex];
    if BtnStopp.Enabled then BtnStopp.Click;
    btnStart.Enabled := true;
    if radRunMode2.Checked or radRunMode1.Checked then
      BtnStart.Click;
  end;
end;

function zweinull(inp: integer): string;
begin
  if inp >= 10 then
    result := inttostr(inp)
  else
    result := '0' + inttostr(inp);
end;

// Millisekunden zu hh:mm:ss
function mstotimestr(inp: integer): string;
var
  h, m, s: integer;
begin
  result := '';
  m := (inp div 1000) div 60;
  h := 0;
  while m >= 60 do
  begin
    inc(h);
    m := m - 60;
  end;
  s := (inp div 1000) - m * 60;
  result := zweinull(h)+':'+zweinull(m)+':'+zweinull(s);
end;

procedure TMainForm.plyTimerTimer(Sender: TObject);
begin
  pgrVolume.Position := 1000 - volWave.Position;
  VolProc.Caption := inttostr(100 - round(volWave.Position / 1000 * 100))+'%';
  if Playing then
  begin
    ggeProgress.Max := mediaplayer.Length;
    ggeProgress.Position := mediaplayer.Position;
    Status1.caption := mstotimestr(mediaplayer.Position) + ' / ' + mstotimestr(mediaplayer.Length);
    Status2.caption := inttostr(floor(ggeprogress.Position / ggeprogress.Max * 100)) + '%';
    if mediaplayer.Position >= mediaplayer.Length then
    begin
      mediaplayer.Rewind;
      nextsong;
    end;
  end;
end;

procedure TMainForm.btnPauseClick(Sender: TObject);
begin
  mediaplayer.Pause;
  btnStart.Enabled := true;
  btnPause.Enabled := false;
end;

procedure TMainForm.BtnStoppClick(Sender: TObject);
begin
  Playing := false;

  mediaplayer.Stop;
  mediaplayer.close;

  ggeProgress.Position := 0;
  ggeProgress.Max := 0;
  Status1.Caption := '00:00:00';
  Status2.Caption := '0%';

  BtnStopp.Enabled := false;
  BtnPause.Enabled := false;
  BtnStart.Enabled := true;
end;

// http://www.wer-weiss-was.de/theme159/article1483880.html
procedure delay(nDelay: Integer);
var 
  nStart : Integer;
begin
  nStart := GetTickCount;
  while Integer(GetTickCount)-nStart < nDelay do
  begin
    Application.ProcessMessages;
    Sleep(0);
  end;
end;

procedure TMainForm.btnStartClick(Sender: TObject);
begin
  if IsFileDRMProtected(mediaplayer.filename) then
  begin
    delay(250);
    NextSong;
  end
  else
  begin

  if btnStopp.Enabled then
    mediaplayer.Play
  else
  begin
    mediaplayer.Open;
    mediaplayer.Play;
    playing := true;
  end;

  BtnStart.Enabled := false;
  BtnPause.Enabled := true;
  BtnStopp.Enabled := true;
  end;

end;

procedure TMainForm.pgrVolumeDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
  pgrVolume.Position := round(pgrVolume.Max * (abs(x)/pgrVolume.Width));
  ActualVolume := round(1000 * (abs(x)/pgrVolume.Width));
  volWave.Position := 1000-ActualVolume;
end;

procedure TMainForm.lstOrdnerChange(Sender: TObject; Node: TTreeNode);
var
  Path, ext: string;
  Aktuell: TTreeNode;
  sr: TSearchRec;
  res, i: integer;
  FCheck: boolean;
begin
  if BtnStopp.Enabled then BtnStopp.Click;
  if BtnStart.Enabled then BtnStart.Enabled := false;

  // Pfad finden
  Aktuell := lstOrdner.Selected;
  lblSongs.caption := Aktuell.Text;
  Path := Aktuell.Text+'\';
  repeat
    try
      if Aktuell.Parent <> nil then
      begin
        Aktuell := Aktuell.Parent;
        Path := Aktuell.Text+'\'+Path;
      end
      else
        Break;
    except end;
  until false;

  if ActualPath <> Path then
  begin
    // Liste leeren
    lstSongs.Items.Clear;
    setlength(ExtentionsArray, 0);

    // Dateien auflisten
    res := FindFirst(Path+'*.*', faAnyFile, sr);
    try
      while (res = 0) do
      begin
        if (sr.name <> '.') and (sr.name <> '..') then
        begin
          try
            ext := lowercase(ExtractFileExt(sr.FindData.cFileName));
            FCheck := false;
            for i := 0 to length(FormatArray)-1 do
              if ext = '.'+FormatArray[i] then
                FCheck := true;
            if FCheck then
            begin
              setlength(ExtentionsArray, length(ExtentionsArray)+1);
              ExtentionsArray[length(ExtentionsArray)-1] := ext;
              lstSongs.items.Add(copy(sr.Name, 0, length(sr.name)-4));
            end;
          except
          end;
        end;
        res := FindNext(sr);
      end;
    finally
      FindClose(sr);
    end;

    ActualPath := Path;
  end;

  if (lstSongs.Items.Count > 0) and radRunMode1.Checked then
  begin
    lstSongs.ItemIndex := 0;
    lstSongs.Selected[0] := true;
    lstSongsClick(self);
    if radRunMode1.Checked then
      btnStart.Click;
  end;
end;

procedure TMainForm.chkRepeatSongClick(Sender: TObject);
begin
  radPlayMode1.Enabled := not chkRepeatSong.Checked;
  radPlayMode2.Enabled := not chkRepeatSong.Checked;
  radPlayMode3.Enabled := not chkRepeatSong.Checked;
end;

procedure TMainForm.SchreibeEinstellung();
var
  PlayMode, RunMode, i: integer;
  RepeatPlay: boolean;
  MusicPath: string;
begin
  // Erkenne Eigenschaften
  RepeatPlay := chkRepeatSong.Checked;
  PlayMode := 1;
  if radPlayMode1.Checked then PlayMode := 1;
  if radPlayMode2.Checked then PlayMode := 2;
  if radPlayMode3.Checked then PlayMode := 3;
  RunMode := 1;
  if radRunMode1.Checked then RunMode := 1;
  if radRunMode2.Checked then RunMode := 2;
  if radRunMode3.Checked then RunMode := 3;

  // Arrays zusammenfassen
  MusicPath := '';
  for i := 0 to length(MusikArray)-1 do
    MusicPath := MusicPath + '|' + MusikArray[i];
  MusicPath := copy(MusicPath, 2, length(MusicPath)-1);

  // Schreibe INI-Einstellungen
  ini := TIniFile.Create(extractfilepath(application.ExeName)+'Settings.ini');
  try
    ini.WriteString('Configuration', 'Path', MusicPath);
    ini.WriteInteger('Configuration', 'PlayMode', PlayMode);
    ini.WriteInteger('Configuration', 'RunMode', RunMode);
    ini.WriteBool('Configuration', 'RepeatPlay', RepeatPlay);
    ini.WriteInteger('Configuration', 'ClientWidth', ClientWidth);
    ini.WriteInteger('Configuration', 'ClientHeight', ClientHeight);
  finally
    ini.Free;
  end;
end;

procedure TMainForm.FormCanResize(Sender: TObject; var NewWidth,
  NewHeight: Integer; var Resize: Boolean);
begin
  if NewHeight < (grpVolume.Top + grpVolume.Height + 8 + btnStart.height + 8 + sbrcopyright.height + GetSystemMetrics(sm_cYsize) + 8) then
    NewHeight := (grpVolume.Top + grpVolume.Height + 8 + btnStart.height + 8 + sbrcopyright.height + GetSystemMetrics(sm_cYsize) + 8);

  if NewWidth <= 720 then NewWidth := 720;  
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  volWave := TWaveVolumeSetting.Create(self);
  volWave.Parent := self;
  volWave.Max := 1000;
  volWave.Visible := false;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  volWave.Free;
  ggeProgress.free;
end;

procedure TMainForm.sbrCopyrightClick(Sender: TObject);
begin
  InfoForm.PopupParent := Screen.ActiveForm; // http://www.delphipraxis.net/topic75743,0,asc,0.html
  InfoForm.showmodal();
end;

procedure TMainForm.btnBeendenClick(Sender: TObject);
begin
  close;
end;

procedure TMainForm.btnOrdnerClick(Sender: TObject);
begin
  ConfigForm.PopupParent := Screen.ActiveForm; // http://www.delphipraxis.net/topic75743,0,asc,0.html
  ConfigForm.showmodal();
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  // Höhenverwaltung
  lstOrdner.Height := MainForm.ClientHeight - lstOrdner.Top - 2 * lstOrdner.Left - sbrCopyright.Height - btnBeenden.Height;
  lstSongs.Height := lstOrdner.Height;
  btnBeenden.Top := lstOrdner.Top + lstOrdner.Height + lstOrdner.Left;
  btnOrdner.Top := btnBeenden.Top;
  ggeProgress.Top := lstSongs.Top + lstSongs.Height + lstOrdner.Left;
  btnStart.Top := ggeProgress.Top;
  btnPause.Top := btnStart.Top;
  btnStopp.Top := btnPause.Top;
  status1.top := ggeProgress.Top + ggeProgress.Height + 2;
  status2.top := status1.top;

  // Breitenverwaltung
  lstSongs.Width := round((MainForm.ClientWidth - 4 * lstOrdner.Left - grpPlayMode.Width) / 2);
  lstOrdner.Width := lstSongs.Width;
  lstSongs.Left := 2 * lstOrdner.Left + lstOrdner.Width;
  grpPlayMode.Left := lstOrdner.Left + lstSongs.Left + lstSongs.Width;
  grpRunMode.Left := grpPlayMode.Left;
  grpVolume.Left := grpPlayMode.Left;
  lblSongs.Left := lstSongs.Left;
  lblOrdner.Left := lstOrdner.Left;
  btnBeenden.Width := round((lstOrdner.Width - btnBeenden.Left) / 2);
  btnOrdner.Width := btnBeenden.Width;
  btnOrdner.Left := 2 * btnBeenden.Left + btnBeenden.Width;
  ggeProgress.Width := lstSongs.Width;
  ggeProgress.Left := lstSongs.Left;
  status1.left := ggeProgress.Left;
  status2.left := ggeProgress.left + ggeProgress.Width - status2.width;
  btnStart.Left := grpPlayMode.Left;
  btnStart.Width := round((grpPlayMode.Width - 2 * lstOrdner.Left) / 100 * 50);
  btnPause.Width := round((grpPlayMode.Width - 2 * lstOrdner.Left) / 100 * 25);
  btnStopp.Width := round((grpPlayMode.Width - 2 * lstOrdner.Left) / 100 * 25);
  btnPause.Left := btnBeenden.Left + btnStart.Left + btnStart.Width;
  btnStopp.Left := btnBeenden.Left + btnPause.Left + btnPause.Width;
end;

procedure TMainForm.NextSong();
var
  actrand: integer;
begin
  if chkRepeatSong.Checked then
    mediaplayer.Play
  else
  begin
    if radPlayMode2.Checked then
    begin
      randomize();
      repeat
        actrand := random(lstSongs.Items.Count);
      until actrand <> lstSongs.ItemIndex;
      lstSongs.ItemIndex := actrand;
      lstSongs.Selected[lstSongs.ItemIndex] := true;
      lstSongsClick(self);
      btnStart.Click;
    end;
    if radPlayMode1.Checked then
    begin
      if lstSongs.ItemIndex+1 = lstSongs.Items.Count then
        lstSongs.ItemIndex := 0
      else
        lstSongs.ItemIndex := lstSongs.ItemIndex+1;
      lstSongs.Selected[lstSongs.ItemIndex] := true;
      lstSongsClick(self);
      btnStart.Click;
    end;
    if radPlayMode3.Checked then
    begin
      ggeProgress.Position := ggeProgress.Min;
      BtnStart.Enabled := true;
      BtnStopp.Enabled := false;
      btnPause.Enabled := false;
    end;
  end;
end;

end.
