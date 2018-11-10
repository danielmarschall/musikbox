unit Config;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, Forms, Dialogs, StdCtrls,
  ActnList, StdActns, ShlObj;

type
  TConfigForm = class(TForm)
    btnAbbrechen: TButton;
    btnSpeichern: TButton;
    grpMusikOrdner: TGroupBox;
    lstMusikOrdner: TListBox;
    btnOrdnerErstellen: TButton;
    btnOrdnerEntfernen: TButton;
    procedure btnAbbrechenClick(Sender: TObject);
    procedure btnSpeichernClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOrdnerEntfernenClick(Sender: TObject);
    procedure btnOrdnerErstellenClick(Sender: TObject);
  private
    lg_StartFolder: String;
  end;

var
  ConfigForm: TConfigForm;

implementation

uses
  Main;

{$R *.dfm}

procedure TConfigForm.btnAbbrechenClick(Sender: TObject);
begin
  close;
end;

procedure TConfigForm.btnSpeichernClick(Sender: TObject);
var
  i: integer;
begin
  setlength(MainForm.MusikArray, 0);
  for i := 0 to lstMusikOrdner.Items.Count-1 do
  begin
    setlength(MainForm.MusikArray, length(MainForm.MusikArray)+1);
    MainForm.MusikArray[length(MainForm.MusikArray)-1] := lstMusikOrdner.Items.Strings[i];
  end;

  MainForm.InitDirectories();
  MainForm.SchreibeEinstellung();

  close;
end;

procedure TConfigForm.FormShow(Sender: TObject);
var
  i: integer;
begin
  lstMusikOrdner.Items.Clear;
  for i := 0 to length(MainForm.MusikArray)-1 do
    lstMusikOrdner.Items.Add(MainForm.MusikArray[i]);
end;

procedure TConfigForm.btnOrdnerEntfernenClick(Sender: TObject);
begin
  if lstMusikOrdner.ItemIndex <> -1 then
    lstMusikOrdner.Items.Delete(lstMusikOrdner.ItemIndex);
end;

///////////////////////////////////////////////////////////////////
// Call back function used to set the initial browse directory.
///////////////////////////////////////////////////////////////////
function BrowseForFolderCallBack(Wnd: HWND; uMsg: UINT;
        lParam, lpData: LPARAM): Integer stdcall;
begin
  if uMsg = BFFM_INITIALIZED then
    SendMessage(Wnd,BFFM_SETSELECTION,1,Integer(@configform.lg_StartFolder[1]));
  result := 0;
end;

///////////////////////////////////////////////////////////////////
// This function allows the user to browse for a folder
//
// Arguments:-
//    browseTitle : The title to display on the browse dialog.
//  NewFolder : Allow to create a new folder
//  initialFolder : Optional argument. Use to specify the folder
//                  initially selected when the dialog opens.
//
// Returns: The empty string if no folder was selected (i.e. if the
//          user clicked cancel), otherwise the full folder path.
///////////////////////////////////////////////////////////////////
function BrowseForFolder(const browseTitle: String; const NewFolder: boolean = false;
        const initialFolder: String =''): String;
var
  browse_info: TBrowseInfo;
  folder: array[0..MAX_PATH] of char;
  find_context: PItemIDList;
const
  BIF_NEWDIALOGSTYLE=$40;
begin
  FillChar(browse_info,SizeOf(browse_info),#0);
  configform.lg_StartFolder := initialFolder;
  browse_info.pszDisplayName := @folder[0];
  browse_info.lpszTitle := PChar(browseTitle);
  if NewFolder then
    browse_info.ulFlags := BIF_RETURNONLYFSDIRS or BIF_NEWDIALOGSTYLE
  else
    browse_info.ulFlags := BIF_RETURNONLYFSDIRS;
  browse_info.hwndOwner := Application.Handle;
  if initialFolder <> '' then
    browse_info.lpfn := BrowseForFolderCallBack;
  find_context := SHBrowseForFolder(browse_info);
  if Assigned(find_context) then
  begin
    if SHGetPathFromIDList(find_context,folder) then
      result := folder
    else
      result := '';
    GlobalFreePtr(find_context);
  end
  else
    result := '';
end;

procedure TConfigForm.btnOrdnerErstellenClick(Sender: TObject);
var
  fol: string;
begin
  fol := BrowseForFolder('Neuen Ordner hinzufügen', true, 'C:\');
  if fol <> '' then
    lstMusikOrdner.Items.Add(fol);
end;

end.
