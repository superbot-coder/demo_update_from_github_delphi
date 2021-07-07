unit UFrmGitUpdate;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, json, Vcl.StdCtrls, System.IOUtils, REST.JSON,
  Vcl.ExtCtrls, Vcl.ComCtrls, sSkinManager, sButton, sMemo, sLabel,
  Vcl.Buttons, sEdit, REST.Types, REST.Client, sListView,
  System.ImageList, Vcl.ImgList, GetVer, FormatFileSizeMod, System.StrUtils,
  Data.Bind.Components, Data.Bind.ObjectScope;

type
  TFrmGitUpdate = class(TForm)
    sSkinManager: TsSkinManager;
    RESTClient: TRESTClient;
    RESTRequest: TRESTRequest;
    RESTResponse: TRESTResponse;
    mmInfo: TsMemo;
    sLVFiles: TsListView;
    ImageList: TImageList;
    sBtnUpdate: TsButton;
    sBtnCheckUpdate: TsButton;
    sEdURLApiReliases: TsEdit;
    sLblUrlRepo: TsLabel;
    procedure FormCreate(Sender: TObject);
    procedure CheckReleases;
    procedure sBtnCheckUpdateClick(Sender: TObject);
    function  CheckVersion(CurrentVer, DownloadVer: String): Boolean;
    function AddLVFilesItems: integer;
    procedure sBtnUpdateClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FrmGitUpdate: TFrmGitUpdate;
  CurrPath: String;
  CurrentVersion: String;
  USERPROFILE: String;
  extArray: array[0..2] of string = ('.zip','.7z','.rar');

  //Url_GitHub_Releases: String;

Const
  CAPTION_MB = 'Проверка обновления';
  URL_GITHUB_RELEASES = 'http://api.github.com/repos/superbot-coder/chia_plotting_tools/releases';
  lv_files = 0;
  lv_size  = 1;
  lv_url   = 2;

  icn_zip  = 0;
  icn_7zip = 1;
  icn_rar  = 2;
  icn_all  = 3;


implementation

{$R *.dfm}

procedure TFrmGitUpdate.sBtnUpdateClick(Sender: TObject);
var
  FileName: string;
begin

  if sLVFiles.Selected = Nil then
  begin
    MessageBox(Handle, PChar('Ни один файл не выбран для скачивания.'),
               PChar(CAPTION_MB), MB_ICONWARNING);
    Exit;
  end;

  RESTClient.BaseURL := sLVFiles.Selected.SubItems[lv_url];
  RESTClient.Accept  := '';
  RESTResponse.RootElement := '';
  RESTRequest.Execute;

  mmInfo.Lines.Add('Идет загрузка файла: ' + sLVFiles.Selected.SubItems[lv_url]);
  mmInfo.Lines.Add('Status: ' + RESTResponse.StatusText);
  if AnsiLowerCase(RESTResponse.StatusText) <> 'ok' then Exit;
  FileName := USERPROFILE + '\Downloads\' + sLVFiles.Selected.SubItems[lv_files];

  TFile.WriteAllBytes(FileName, RESTResponse.RawBytes);

  If FileExists(FileName) then
    MessageBox(Handle, PChar('Файл "' + sLVFiles.Selected.SubItems[lv_files] + '" успешно загружен!'),
      PChar(CAPTION_MB), MB_ICONINFORMATION)
  else
    MessageBox(Handle, PChar('Загружаемый файл "' + sLVFiles.Selected.SubItems[lv_files] + '" чегото не найден...'),
      PChar(CAPTION_MB), MB_ICONINFORMATION);
end;

function TFrmGitUpdate.AddLVFilesItems: integer;
begin
  with sLVFiles.Items.Add do
  begin
    Caption := IntToStr(index +1);
    ImageIndex := -1;
    SubItems.Add('');
    SubItems.Add('');
    SubItems.Add('');
    Result := index;
  end;
end;

procedure TFrmGitUpdate.CheckReleases;
var
  LastRelease: TJSONObject;
  tag_name: string;
  StrValue: string;
  FileName: string;
  vJSONBytes : TBytes;
  assetsArray: TJSONArray;
  // ReleaseObj : TJSONArray;
  i, x: Word;
  icn: ShortInt;
begin

  RESTClient.BaseURL       := sEdURLApiReliases.Text;
  RESTClient.Accept        := 'application/json';
  RESTResponse.RootElement := '[0]';
  RESTRequest.Execute;

  // Проверка, что нужный ресурс найден
  if AnsiLowerCase(RESTResponse.StatusText) <> 'ok' then
  begin
    mmInfo.Lines.Add('Status: ' + RESTResponse.StatusText);
    //mmInfo.Lines.Add(StringOfChar('-', 50));
    //mmInfo.Lines.Add('[Additional information]');
    //mmInfo.Lines.Add(RESTResponse.Headers.Text);
    Exit;
  end;

  mmInfo.Lines.Add('Status: ' + RESTResponse.StatusText);

  if RESTResponse.JSONValue = Nil then
  begin
    mmInfo.Lines.Add('JSONValue = Nil');
    Exit;
  end;

  // ---- Если нужно протестировать из файла .json --------------
  //FileName    := 'C:\PROJECT+\T E S T\testGitCheckRelise\releases.json';
  //vJSONBytes  := TFile.ReadAllBytes(FileName);
  //ReleaseObj  := TJSONObject.ParseJSONValue(vJSONBytes, 0) as TJSONArray;
  //LastRelease := ReleaseObj.Items[0] as TJSONObject;
  //------------------------------------------------------------

  try
    LastRelease := RESTResponse.JSONValue as TJSONObject;
    if LastRelease.FindValue('tag_name') = Nil then
    begin
      mmInfo.Lines.Add('Не найден параметр: tag_name');
      exit;
    end;

    tag_name := LastRelease.GetValue('tag_name').Value;
    CurrentVersion := GetVertionInfo(Application.ExeName, true);
    if CheckVersion(CurrentVersion, tag_name) = False then
    begin
      mmInfo.Lines.Add('Ваша версия программы ' + CurrentVersion +
                     ' является самой актуальной');
      Exit;
    end;

    mmInfo.Lines.Add('Было обнаружена новая версия программы: ' + tag_name);
    if LastRelease.FindValue('body') <> Nil then
    begin
      mmInfo.Lines.Add('Описание:');
      mmInfo.Lines.Add(LastRelease.GetValue('body').Value);
    end;

    if LastRelease.FindValue('assets') = Nil then
    begin
      mmInfo.Lines.Add('Not found the parametr: "assets"');
      mmInfo.Lines.Add('The End!');
      Exit;
    end;

    assetsArray := LastRelease.GetValue('assets')  as TJSONArray;
    for i:=0 to assetsArray.Count -1 do
    begin
      x := AddLVFilesItems;
      sLVFiles.Items[x].SubItems[lv_files] := assetsArray.Items[i].FindValue('name').Value;
      StrValue := assetsArray.Items[i].FindValue('size').Value;
      sLVFiles.Items[x].SubItems[lv_size]  := FormatFileSize(StrToInt64(StrValue));
      StrValue := assetsArray.Items[i].FindValue('browser_download_url').Value;
      sLVFiles.Items[x].SubItems[lv_url]   := StrValue;
      // Set icontype
      StrValue := ExtractFileExt(StrValue);
      icn := AnsiIndexStr(StrValue, extArray);
      if icn = -1 then icn := icn_all;
      sLVFiles.Items[x].SubItemImages[lv_files] := icn;
      sLVFiles.Items[x].SubItemImages[lv_url]   := icn;
    end;

  finally
    // ReleaseObj.DisposeOf;
  end;

end;

function TFrmGitUpdate.CheckVersion(CurrentVer, DownloadVer: String): Boolean;
var
  i: Byte;
  CurrentV, DownloadV: Word;
  s_temp: string;
  Numbers: set of char;
begin

  // ВАЖНО! ATTENTION!
  // Данная фукция является только демонстрацией
  // и не является правильной может работать с ошибками
  // Для более правильного сравнения разных версий программ
  // вам необходимо сделать новую функцию или модернизировать эту 
 
  Numbers := ['0'..'9'];
  s_temp  := '';
  for i := 1 to Length(CurrentVer) do
    if CurrentVer[i] in Numbers then s_temp := s_temp + CurrentVer[i];
  CurrentV := StrToInt(s_temp);

  s_temp  := '';
  for i := 1 to Length(DownloadVer) do
    if DownloadVer[i] in Numbers then s_temp := s_temp + DownloadVer[i];
  DownloadV := StrToInt(s_temp);

  if CurrentV < DownloadV then
    Result := True
  else
    Result := false;
end;

procedure TFrmGitUpdate.FormCreate(Sender: TObject);
begin
  CurrPath := ExtractFilePath(Application.ExeName);
  USERPROFILE := GetEnvironmentVariable('USERPROFILE');
end;

procedure TFrmGitUpdate.sBtnCheckUpdateClick(Sender: TObject);
begin
  CheckReleases;
end;

end.
