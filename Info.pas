unit Info;

interface

uses
  Windows, SysUtils, Classes, Forms, StdCtrls, ExtCtrls, ShellApi,
  Graphics, Controls, wininet;

type
  TInfoForm = class(TForm)
    lblInfo1: TLabel;
    lblInfo2: TLabel;
    lblInfo3: TLabel;
    lblInfo4: TLabel;
    imgCD: TImage;
    imgWeb: TImage;
    lblWeb1: TLabel;
    lblWeb2: TLabel;
    lblClose: TButton;
    Button1: TButton;
    procedure lblCloseClick(Sender: TObject);
    procedure lblWeb1Click(Sender: TObject);
    procedure lblWeb2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  end;

var
  InfoForm: TInfoForm;

implementation

{$R *.dfm}

// http://www.delphipraxis.net/post43515.html
Function GetHTML(AUrl: string): string;
var
  databuffer : array[0..4095] of char;
  ResStr : string;
  hSession, hfile: hInternet;
  dwindex,dwcodelen,dwread,dwNumber: cardinal;
  dwcode : array[1..20] of char;
  res    : pchar;
  Str    : pchar;
begin
  ResStr:='';
  if pos('http://',lowercase(AUrl))=0 then
     AUrl:='http://'+AUrl;

  // Hinzugefügt
  application.ProcessMessages;

  hSession:=InternetOpen('InetURL:/1.0',
                         INTERNET_OPEN_TYPE_PRECONFIG,
                         nil,
                         nil,
                         0);
  if assigned(hsession) then
  begin
    // Hinzugefügt
    application.ProcessMessages;

    hfile:=InternetOpenUrl(
           hsession,
           pchar(AUrl),
           nil,
           0,
           INTERNET_FLAG_RELOAD,
           0);
    dwIndex  := 0;
    dwCodeLen := 10;

    // Hinzugefügt
    application.ProcessMessages;

    HttpQueryInfo(hfile,
                  HTTP_QUERY_STATUS_CODE,
                  @dwcode,
                  dwcodeLen,
                  dwIndex);
    res := pchar(@dwcode);
    dwNumber := sizeof(databuffer)-1;
    if (res ='200') or (res ='302') then
    begin
      while (InternetReadfile(hfile,
                              @databuffer,
                              dwNumber,
                              DwRead)) do
      begin

        // Hinzugefügt
        application.ProcessMessages;

        if dwRead =0 then
          break;
        databuffer[dwread]:=#0;
        Str := pchar(@databuffer);
        resStr := resStr + Str;
      end;
    end
    else
      ResStr := 'Status:'+res;
    if assigned(hfile) then
      InternetCloseHandle(hfile);
  end;

  // Hinzugefügt
  application.ProcessMessages;

  InternetCloseHandle(hsession);
  Result := resStr; 
end;

procedure TInfoForm.Button1Click(Sender: TObject);
var
  temp: string;
begin
  temp := GetHTML('http://www.viathinksoft.de/update/?id=musikbox');
  if copy(temp, 0, 7) = 'Status:' then
  begin
    Application.MessageBox('Ein Fehler ist aufgetreten. Wahrscheinlich ist keine Internetverbindung aufgebaut, oder der der ViaThinkSoft-Server temporär offline.', 'Fehler', MB_OK + MB_ICONERROR)
  end
  else
  begin
    if GetHTML('http://www.viathinksoft.de/update/?id=musikbox') <> '1.5' then
    begin
      if Application.MessageBox('Eine neue Programmversion ist vorhanden. Möchten Sie diese jetzt herunterladen?', 'Information', MB_YESNO + MB_ICONASTERISK) = ID_YES then
        shellexecute(application.handle, 'open', pchar('http://www.viathinksoft.de/update/?id=@musikbox'), '', '', sw_normal);
    end
    else
    begin
      Application.MessageBox('Es ist keine neue Programmversion vorhanden.', 'Information', MB_OK + MB_ICONASTERISK);
    end;
  end;
end;

procedure TInfoForm.lblCloseClick(Sender: TObject);
begin
  close;
end;

procedure TInfoForm.lblWeb1Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://www.daniel-marschall.de/', nil, nil, SW_SHOWNORMAL);
end;

procedure TInfoForm.lblWeb2Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://www.viathinksoft.de/', nil, nil, SW_SHOWNORMAL);
end;

end.
