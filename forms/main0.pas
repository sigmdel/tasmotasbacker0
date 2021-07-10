unit main0;

{$mode objfpc}{$H+}

interface

// Set these defines to help in determining the timeout and retry
// parameters of the HTTP request function
// See log() function below
//
{ -- $DEFINE DEBUG_HTTP_REQUEST}
{ -- $DEFINE DEBUG_BACKUP}
{ -- $DEFINE DEBUG_HTTP_SCAN}
{ -- $DEFINE TIME_HTTP_SCAN}   // this will not update the found devices

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Spin, EditBtn, Grids, Menus, ipv4;

type

  { TMainForm }

  TMainForm = class(TForm)
    ApplicationProperties1: TApplicationProperties;
    Back2Button: TButton;
    FirstIPEdit: TEdit;
    ImageList1: TImageList;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label23: TLabel;
    ExcludeCheckBox: TCheckBox;
    IncludeCheckBox: TCheckBox;
    Label26: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    LastIPEdit: TEdit;
    ExcludeListBox: TListBox;
    IncludeListBox: TListBox;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    N2: TMenuItem;
    PopupMenu1: TPopupMenu;
    FullRangeRadioButton: TRadioButton;
    RadioButton8: TRadioButton;
    ResetButton: TButton;
    AllOptionsCheckBox: TCheckBox;
    DateFormatEdit: TComboBox;
    DeviceGrid: TStringGrid;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Next1Button: TButton;
    Next2Button: TButton;
    OptionsButton: TButton;
    BackupButton: TButton;
    Panel1: TPanel;
    QuitButton: TButton;
    BackButton: TButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    SaveButton: TButton;
    CheckBox1: TCheckBox;
    DateEdit: TDateEdit;
    DirectoryEdit: TDirectoryEdit;
    Label14: TLabel;
    Page5: TPage;
    OptionsGrid: TStringGrid;
    DownloadAttemptsEdit: TSpinEdit;
    ScanAttemptsEdit: TSpinEdit;
    ScanTimeoutEdit: TSpinEdit;
    SubnetBitsEdit: TSpinEdit;
    SubnetEdit: TEdit;
    DownloadTimeoutEdit: TSpinEdit;
    Label11: TLabel;
    Label12: TLabel;
    Page4: TPage;
    ResGrid: TStringGrid;
    ExtensionEdit: TEdit;
    Label10: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Notebook1: TNotebook;
    Page1: TPage;
    Page2: TPage;
    Page3: TPage;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    procedure ApplicationProperties1Idle(Sender: TObject; var Done: Boolean);
    procedure Back2ButtonClick(Sender: TObject);
    procedure ExcludeCheckBoxChange(Sender: TObject);
    procedure FirstIPEditEditingDone(Sender: TObject);
    procedure ExcludeListBoxDblClick(Sender: TObject);
    procedure IncludeCheckBoxChange(Sender: TObject);
    procedure IncludeListBoxDblClick(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure PopupMenu1Close(Sender: TObject);
    procedure PopupMenu1Popup(Sender: TObject);
    procedure ResetButtonClick(Sender: TObject);
    procedure AllOptionsCheckBoxChange(Sender: TObject);
    procedure DateFormatEditChange(Sender: TObject);
    procedure DeviceGridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Next1ButtonClick(Sender: TObject);
    procedure Next2ButtonClick(Sender: TObject);
    procedure OptionsButtonClick(Sender: TObject);
    procedure BackupButtonClick(Sender: TObject);
    procedure BackButtonClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure DeviceListClickCheck(Sender: TObject);
    procedure ExtensionEditChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure GridClick(Sender: TObject);
    procedure Page2BeforeShow(ASender: TObject; ANewPage: TPage;
      ANewIndex: Integer);
    procedure Page4BeforeShow(ASender: TObject; ANewPage: TPage;
      ANewIndex: Integer);
    procedure Page5BeforeShow(ASender: TObject; ANewPage: TPage;
      ANewIndex: Integer);
    procedure QuitButtonClick(Sender: TObject);
    procedure GridHeaderSized(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure GridResize(Sender: TObject);
    procedure ResGridDblClick(Sender: TObject);
    procedure ResGridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure SaveButtonClick(Sender: TObject);
    procedure ScanAttemptsEditChange(Sender: TObject);
    procedure SubnetBitsEditChange(Sender: TObject);
    procedure SubnetEditDone(Sender: TObject);
  private
    popx: integer;
    popy: integer;
    currentCol: integer;
    resizinggrid: boolean;
    updategrid: TObject;
    newdev: boolean;
    fip, lip: TIPv4;
    maxRequestTimeProp: single;
    procedure CalcMaxRequestTime;
    procedure FixupAllIpHint;
    procedure FixupIpRangeHint;
    function GetExtension: string;
    procedure GetDevicesWithHttpScan;
    procedure UpdateCheckCount;
    procedure CopyResGridToClipbrd(delim: char);
  public

  end;

var
  MainForm: TMainForm;

implementation

uses
  clipbrd, fileinfo, options, ssockets, fphttpclient, iplistEdit, math;

{$R *.lfm}


{$IFDEF DEBUG_HTTP_REQUEST}
  {$DEFINE DO_LOG}
{$ENDIF}

{$IFDEF DEBUG_BACKUP}
  {$DEFINE DO_LOG}
{$ENDIF}

{$IFDEF DEBUG_HTTP_SCAN}
  {$DEFINE DO_LOG}
{$ENDIF}

{$IFDEF DEFINE TIME_HTTP_SCAN}
  {$DEFINE DO_LOG}
{$ENDIF}

{  Utility functions }

{$IFDEF DO_LOG}

// In Linux system, messages sent to the Log function are displayed
// on the standard output. To see the output launch the utility in
// a terminal, not from GUI file namanger.
//
// In Windows, messages  are saved to a log file named tasmotasbacker.log

var
  lastic: longint = 0;
  logopened: boolean = false;

procedure log(msg: string);
var
  tic: QWORD;
  i: integer;
begin
  tic := GetTickCount64;
  if not logopened then begin
     {$IFDEF MSWINDOWS}
     close(StdOut);
     assign(StdOut,  changefileext(application.ExeName, '.log'));
     rewrite(StdOut);
     {$ENDIF}
     writeln(StdOut, 'time':18, 'diff':8,'   ', 'message');
     logopened := true;
  end;
  for i := 1 to length(msg) do
    if (msg[i] < ' ') or (msg[i] > '~') then msg[i] := '?';
  writeln(StdOut, timetostr(now), '.', tic, tic-lastic:8, '   ', msg);
  lastic := tic;
end;
{$ENDIF}

// kludge to give some time to the gui to update itself while
// waiting for responses from the MQTT broker and HTTP requests
procedure Delay(dt: QWORD);
var
  tcount : QWORD;
begin
  tcount := GetTickCount64;
  while (GetTickCount64 - tcount < dt) and (not Application.Terminated) do
    Application.ProcessMessages;
end;

{
TSocketErrorType = (
 0  seHostNotFound,
 1  seCreationFailed,
 2  seBindFailed,
 3  seListenFailed,
 4  seConnectFailed,
 5  seConnectTimeOut,
 6  seAcceptFailed,
 7  seAcceptWouldBlock,
 8  seIOTimeOut);
}
function HttpRequest(const aURL: string; out code: integer; out rawdata: string; maxtries: integer = 3; backoff: integer = 4000): boolean;
var
  i: integer;
  {$IFDEF DEBUG_HTTP_REQUEST}
  gotE: boolean;
  eclass: string;
  emsg: string;
  {$ENDIF}
begin
  {$IFDEF DEBUG_HTTP_REQUEST}
  lastic := GetTickCount64;
  log(Format('HttpRequest(url: %s, maxtries: %d, timeout: %d)', [aURL, maxtries, backoff]));
  {$ENDIF}
  rawdata := '';
  code := -1;
  with TFPHTTPClient.create(nil) do try
    KeepConnection := False;
    for i := 0 to maxtries-1 do begin
      ConnectTimeOut := (i+1)*backoff;
      delay(2);
      {$IFDEF DEBUG_HTTP_REQUEST}
      gotE := false;
      eclass := '';
      emsg := '';
      rawdata := '';
      {$ENDIF}
      try
        rawdata := Get(aURL);
        code := ResponseStatusCode;
        {$IFDEF DEBUG_HTTP_REQUEST}
        log(Format('  request returns after %d tries with code = %d, data = %s', [i+1, code, copy(rawdata, 1, 64)]));
        {$ENDIF}
        exit;
      except
        {$IFDEF DEBUG_HTTP_REQUEST}
        On E: Exception do begin
          gotE := true;
          eclass := E.classname;
          emsg := E.Message;
          if E is ESocketError then
            code := integer(ESocketError(E).Code)
          else
            code := ResponseStatusCode;
        end;
        {$ELSE}
        On  E: ESocketError do
          code := integer(E.Code);
        else
          code := ResponseStatusCode;
        rawdata := ResponseStatusText;
        {$ENDIF}
      end;
      {$IFDEF DEBUG_HTTP_REQUEST}
      if gotE then
        log(Format('  Exception class %s, message %s, code %d, try %d', [eclass, emsg, code, i+1]));
      {$ENDIF};
      if (code = 404) or (code = integer(seConnectFailed)) or (code = integer(seHostNotFound)) then begin
        {$IFDEF DEBUG_HTTP_REQUEST}
        log(Format('  request returns after %d tries with code = %d, data = %s', [i+1, code, copy(rawdata, 1, 64)]));
        {$ENDIF}
        exit;
      end;
      {$IFDEF DEBUG_HTTP_REQUEST}
      log(Format('  http request attemp %d failed with code: %d', [i+1, code]));
      {$ENDIF}
    end; // for loop
  finally
    result := code = 200;
    Free;
  end;
  {$IFDEF DEBUG_HTTP_SCAN}
  log(Format('  http request returns after %d tries with code = %d, data = %s', [i+1, code, copy(rawdata, 1, 64)]));
  {$ENDIF}
end;

//Save a string as a file
procedure SaveStringToFile(const s, filename: string);
var
  F: TextFile;
begin
  AssignFile(F, filename);
  try
    ReWrite(F);
    Write(F, s);
  finally
    CloseFile(F);
  end;
end;

// Converts value seconds into a  'xx minutes xx seconds' string
// if value < 120 then no minutes shown
function SecondsToStr(value: integer): string;
begin
  if value <= 0 then
    result := ''
  else if value < 120 then
    result := Format(' %d seconds', [value])
  else
    result := Format(' %d minutes%s', [value div 60, SecondsToStr(value mod 60)]);
end;

{ TMainForm }

procedure TMainForm.AllOptionsCheckBoxChange(Sender: TObject);
var
  b: string;
  i: integer;
begin
  if AllOptionsCheckBox.Checked then
    b := '1'
  else
    b := '0';
  for i := 0 to OptionsGrid.RowCount-1 do
    OptionsGrid.cells[0, i] := b;
end;

procedure TMainForm.ApplicationProperties1Idle(Sender: TObject;
  var Done: Boolean);
begin
  if newdev then begin
    UpdateCheckCount;
    newdev := false;
    invalidate;
    application.processMessages;
  end;
  if assigned(updategrid) then begin
    GridResize(updateGrid);
    updategrid := nil;
  end;
end;

procedure TMainForm.Back2ButtonClick(Sender: TObject);
begin
  DeviceGrid.RowCount := 1;
  Notebook1.PageIndex := 0;
end;

procedure TMainForm.ExcludeCheckBoxChange(Sender: TObject);
begin
  FixupAllIpHint;
  FixupIpRangeHint;
end;

procedure TMainForm.BackButtonClick(Sender: TObject);
begin
  Notebook1.PageIndex := 1;
end;

procedure TMainForm.BackupButtonClick(Sender: TObject);
var
  i: integer;
  ip, device, s1, s2: string;
  url, html: String;
  aRow: integer;
  resstring: string;
  code, count: integer;
begin
  Notebook1.PageIndex := 3;
  Notebook1.Invalidate;
  Notebook1.Update;
  Label19.caption := ExpandFilename(DirectoryEdit.Directory);
  application.ProcessMessages;
  screen.Cursor := crHourglass;
  OptionsButton.enabled := false;
  try
    count := 0;
    for i := 1 to DeviceGrid.RowCount-1 do begin
      ip := trim(DeviceGrid.cells[1, i]);
      if radioButton3.checked then
        device := trim(DeviceGrid.cells[2, i])
      else
        device := trim(DeviceGrid.cells[3, i]);
       aRow := ResGrid.RowCount;
       ResGrid.RowCount := aRow + 1;
       ResGrid.Cells[0, aRow] := ip;
       ResGrid.Cells[1, aRow] := device;
       if DeviceGrid.cells[0, i] = '0' then
         resstring := 'not selected'
       else begin
         if radiobutton1.checked then begin
           s1 := trim(device);
           s2 := DateEdit.Text;
         end
         else begin
           s1 := DateEdit.Text;
           s2 := trim(device);
         end;
         device := Format('%s%s%s-%s%s',
           [DirectoryEdit.Directory,  DirectorySeparator, s1, s2, GetExtension]);
         if count = 0 then
           ForceDirectories(DirectoryEdit.Directory);
         url := 'http://' + ip + '/dl';
         html := '';
         {$IFDEF DEBUG_BACKUP}
         log('Backup - reading '+ url);
         {$ENDIF}

         if HttpRequest(url, code, html, DownloadAttemptsEdit.value,
           DownloadTimeoutEdit.value*1000) and (html <> '') then begin
           SaveStringToFile(html, device);
           {$IFDEF DEBUG_BACKUP}
           log(' Saved to ' + device);
           {$ENDIF}
           resstring := Format('saved to %s', [extractFilename(device)]);
         end
         else begin
           resstring := Format('http error %d', [code]);
         end;
         inc(count);
       end;
       ResGrid.Cells[2, aRow] := resstring;
       ResGrid.invalidate;
       ResGrid.Update;
       application.ProcessMessages;
    end;
  finally
    screen.Cursor := crDefault;
  end;
  OptionsButton.enabled := true;
  OptionsButton.setFocus;
end;

(*
 let w be the timeout, then at each try the timeout value will be

 try   timeout
  1       w  =  2^(1-1) w
  2      2w  =  2^(2-1) w
  3      4w  =  2^(3-1) w
  4      8w  =  2^(4-1) w
  ...
  i             2^(i-1) w
  ...
  n             2^(n-1) w

Total wait for a request after n tries is
  w * sum{i=1 to n} 2^(i-1)

But sum{i=1 to n} 2^(i-1) is equal to
    sum{i=0 to n-1} 2^i

Now the sum{i=0 to k} 2^i is 2^(k+1) - 1 so
   sum{i=0 to n-1} 2^i = 2^(n-1+1) - 1 = 2^n - 1

So the wait time for one HTTP request done n tries is w *(2^n - 1)
*)
procedure TMainForm.CalcMaxRequestTime;
begin
  MaxRequestTimeProp := ScanTimeoutEdit.value * (intpower(2, ScanAttemptsEdit.value) - 1);
end;

procedure TMainForm.CheckBox1Change(Sender: TObject);
var
  b: string;
  i: integer;
begin
  if CheckBox1.Checked then
    b := '1'
  else
    b := '0';
  for i := 0 to DeviceGrid.RowCount-1 do
    DeviceGrid.cells[0, i] := b;
  UpdateCheckCount;
end;

procedure TMainForm.CopyResGridToClipbrd(delim: char);
var
  stream: TStringStream;
begin
  stream := TStringStream.create;
  try
    ResGrid.SaveToCSVStream(stream, delim);
    Clipboard.AsText := stream.DataString;
  finally
    stream.free;
  end;
end;

procedure TMainForm.DateFormatEditChange(Sender: TObject);
begin
   DateEdit.DateOrder := TDateOrder(DateFormatEdit.ItemIndex + 1);
end;

procedure TMainForm.DeviceGridSelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
begin
   currentcol := aCol;
   CanSelect := aCol = 0;
end;

procedure TMainForm.DeviceListClickCheck(Sender: TObject);
begin
  UpdateCheckCount;
end;

procedure TMainForm.ExcludeListBoxDblClick(Sender: TObject);
begin
  EditIPList(ExcludeListBox.Items)
end;

procedure TMainForm.ExtensionEditChange(Sender: TObject);
var
  newext: string;
begin
  newext := GetExtension;
  RadioButton1.Caption := ChangeFileExt(RadioButton1.caption, newext);
  RadioButton2.Caption := ChangeFileExt(RadioButton2.caption, newext);
end;

procedure TMainForm.FirstIPEditEditingDone(Sender: TObject);
begin
  FixupIpRangeHint;
end;

procedure TMainForm.FixupAllIpHint;
var
  mask: TIPv4;
  ttime: integer;
  nips: integer;
begin
  mask := not SubnetMask(SubnetBitsEdit.value);
  nips := mask.value - 2 - ExcludeListBox.Count*ord(ExcludeCheckBox.Checked);
  ttime := round( nips * MaxRequestTimeProp ) ;
  FullRangeRadioButton.Hint := Format('Could take up to %s', [SecondsToStr(ttime)]);
end;

procedure TMainForm.FixupIpRangeHint;
var
  lfip, llip: TIpv4;
  ttime: integer;
  nips: integer;
begin
  if TryStrToIPv4(FirstIpEdit.text, lfip)
  and TryStrToIPv4(LastIpEdit.text, llip) then begin
    nips := llip.value - lfip.value + 1
      - ExcludeListBox.Count*ord(ExcludeCheckBox.Checked)
      + IncludeListBox.Count*ord(IncludeCheckBox.Checked);
    ttime := round( nips * MaxRequestTimeProp ) ;
    RadioButton8.Hint := Format('Could take up to %s', [SecondsToStr(ttime)]);
    label23.Hint := RadioButton8.Hint;
    FirstIPEdit.Hint := RadioButton8.Hint;
    LastIPEdit.Hint := RadioButton8.Hint;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
var
  Version : TProgramVersion;
begin
  if GetProgramVersion(Version) then with Version do
    caption := Format('Tasmotas Backer 0 [%d.%d.%d]', [Major,Minor,Revision])
  else
     caption := 'Tasmotas Backer 0';

  SubnetEdit.Text := params.Subnet;
  SubnetBitsEdit.value := params.SubnetBits;
  FullRangeRadioButton.Checked := params.ScanAllIP;
  RadioButton8.Checked := not params.ScanAllIP;
  FirstIpEdit.Text := params.FirstIP;
  LastIPEdit.Text := params.LastIP;
  ScanAttemptsEdit.value := params.ScanAttempts;
  ScanTimeoutEdit.value := params.ScanTimeout;
  DirectoryEdit.directory := params.directory;
  ExtensionEdit.text := params.extension;
  DateFormatEdit.ItemIndex := params.dateformat;
  DateEdit.DateOrder := TDateOrder(DateFormatEdit.ItemIndex + 1);
  if params.FilenameFormat = 0 then
    RadioButton1.Checked := true
  else
    RadioButton2.Checked := true;
  if params.DeviceName = 0 then
    RadioButton3.Checked := true
  else
    RadioButton4.Checked := true;
  DownloadAttemptsEdit.Value := params.DownloadAttempts;
  DownloadTimeoutEdit.Value := params.DownloadTimeout;
  ScanAttemptsEdit.value := params.ScanAttempts;
  ScanTimeoutEdit.Value := params.ScanTimeout;
  IncludeListBox.Items.assign(params.IncludeIPs);
  ExcludeListBox.Items.assign(params.ExcludeIPs);
  CalcMaxRequestTime;
  FixupAllIpHint;
  FixupIpRangeHint;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // nothing to do
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
  if not resizinggrid then begin
    resizinggrid := true;
    {
    try
      GridResize(DeviceGrid);
      GridResize(ResGrid);
      GridResize(OptionsGrid);
    finally
      invalidate;
    end;
    }
    try
      case Notebook1.PageIndex of
        1: GridResize(DeviceGrid);
        3: GridResize(ResGrid);
        4: GridResize(OptionsGrid);
        else exit;
      end;
      invalidate;
    finally
      resizinggrid := false;
    end;
  end;
end;

procedure TMainForm.GetDevicesWithHttpScan;
const
  URLB = 'http://%s/cm?cmnd=';
var
  myHostname, myTopic, myIps: string;
  code: integer;
  url: string;
  {$IFDEF TIME_HTTP_SCAN}
  deb, fin: TDateTime;
  {$ELSE}
  r: integer;
  {$ENDIF}

  excount: integer;
  incount: integer;
  i, j: integer;
  ip: TIPv4;
  v, fv, lv: longword;


  function FindValue(const key: string; var value: string): boolean;
  var
    p: integer;
  begin
    result := true;
    p := pos('"' + key + '":"', value);
    if p > 0 then begin
      delete(value, 1, p + length(key)+3);
      p := pos('"', value);
      if p > 0 then begin
        delete(value, p, maxint);
        exit;
      end;
    end;
    value := '';
    result := false;
  end;

  procedure CheckIP(aIP: TIPv4);
  begin
    myIps := aip.ToString;
    url := Format(URLB, [myIps]);
    myHostname := '';
    myTopic := '';
    {$IFNDEF TIME_HTTP_SCAN}
    label11.Caption := 'Checking ' + myIps;
    label11.Repaint;
    delay(2);
    {$ENDIF}
    if not HttpRequest(url + 'hostname', code, myHostname, ScanAttemptsEdit.value, ScanTimeOutEdit.value*1000) then
    //if not HttpRequest(url + 'hostname', code, myHostname) then
      exit;
    if not FindValue('Hostname', myHostname) then
      exit;
    if not HttpRequest(url + 'topic', code, myTopic, ScanAttemptsEdit.value, ScanTimeOutEdit.value*1000) then
    //if not HttpRequest(url + 'topic', code, myTopic) then
      exit;
    if not FindValue('Topic', myTopic) then
      exit;
    {$IFNDEF TIME_HTTP_SCAN}
    with DeviceGrid do begin
       r := RowCount;
       RowCount := RowCount+1;
       cells[0, r] := '1';
       cells[1, r] := myIps;
       cells[2, r] := myTopic;
       cells[3, r] := myHostname;
       MainForm.newdev := true;
    end;
    notebook1.invalidate;
    Delay(2);
    {$ENDIF}
  end;

begin
  Next2Button.Enabled := false;
  Screen.Cursor := crHourGlass;
  {$IFDEF TIME_HTTP_SCAN}
  deb := time;
  {$ENDIF}
  excount := 0;
  incount := 0;
  // get valid excluded IPs
  if ExcludeCheckBox.checked then begin
    for i := 0 to ExcludeListBox.count-1 do begin
      if (not ip.TryFromString(ExcludeListBox.Items[i]))
      or (ip < fip) or (ip > lip) then
        continue;
      ExcludeListBox.Items.Objects[excount] := TObject(intptr(ip.value));
      inc(excount);
    end;
  end;
  // get valid incldued IPs
  if IncludeCheckBox.checked then begin
    for i := 0 to IncludeListBox.count-1 do begin
      if (not ip.TryFromString(IncludeListBox.Items[i]))
      or ((fip <= ip) and (ip <= lip)) then
        continue;
      IncludeListBox.Items.Objects[incount] := TObject(intptr(ip.value));
      inc(incount);
    end;
  end;
  fv := fip.value;
  lv := lip.value;
  try
    for v := fv to lv do begin
      ip.value := v;
      // check if it is in excluded IP
      for j := 0 to excount-1 do
        if longword(ptrint(ExcludeListBox.Items.Objects[j])) = v then begin
          ip.value := 0;
          break;
        end;
      if ip.value <> 0 then
        CheckIp(ip);
    end;
    for i := 0 to incount-1 do begin
      ip.value := longword(ptrint(IncludeListBox.Items.Objects[i]));
      CheckIp(ip);
    end;
    {$IFDEF TIME_HTTP_SCAN}
    fin := now;
    log(Format('HTTP scan time: %s ms', [TimeToStr(fin-deb)]));
    {$ENDIF}
  finally
    Screen.Cursor := crDefault;
    next2Button.Enabled := true;
    next2Button.SetFocus;
  end;
end;

function TMainForm.GetExtension: string;
begin
  result := ExtensionEdit.Text;
  if (result = '.') then
    result := ''
  else if (result <> '') and (result[1] <> '.') then
    insert('.', result, 1);
end;

procedure TMainForm.GridClick(Sender: TObject);
begin
  with Sender as TStringGrid do begin
    if (currentcol = 0) and (row > 0) then begin
      if Cells[0, Row] = '0' then
         Cells[0, Row] := '1'
      else
         Cells[0, Row] := '0';
    end;
  end;
end;

procedure TMainForm.GridHeaderSized(Sender: TObject; IsColumn: Boolean;
  Index: Integer);
begin
  if not resizinggrid then
    GridResize(sender);
end;

procedure TMainForm.GridResize(Sender: TObject);
var
  wd, j: integer;
begin
  with Sender as TStringGrid do begin
    wd := clientwidth - colcount;
    for j := 0 to Colcount-2 do
      dec(wd, colwidths[j]);
    colwidths[colcount-1] := wd;
  end;
end;

procedure TMainForm.IncludeCheckBoxChange(Sender: TObject);
begin
  FixupIpRangeHint;
end;

procedure TMainForm.IncludeListBoxDblClick(Sender: TObject);
begin
  EditIPList(IncludeListBox.Items)
end;

procedure TMainForm.MenuItem1Click(Sender: TObject);
var
  delim: char;
begin
  if MenuItem3.checked then
    delim := #9
  else
    delim := ',';
  CopyResGridToClipbrd(delim);
end;

procedure TMainForm.MenuItem2Click(Sender: TObject);
begin
  PopupMenu1.popup(popx, popy);
end;

procedure TMainForm.MenuItem3Click(Sender: TObject);
begin
  PopupMenu1.popup(popx, popy);
end;

procedure TMainForm.Next1ButtonClick(Sender: TObject);
begin
  if radioButton8.checked then begin
    fip.FromString(FirstIpEdit.Text);
    lip.FromString(LastIPEdit.Text);
  end
  else begin
    fip.FromString(SubnetEdit.Text);
    SubnetRange(fip, SubnetBitsEdit.value, fip, lip);
    fip.inc;
    lip.dec;
  end;
  Notebook1.PageIndex := 1;
  CheckBox1.SetFocus;
  Notebook1.invalidate;
  Delay(2);
  GetDevicesWithHttpScan;
end;

procedure TMainForm.Next2ButtonClick(Sender: TObject);
begin
  DateEdit.Date := date;
  Notebook1.PageIndex := 2;
  DirectoryEdit.SetFocus;
end;

procedure TMainForm.OptionsButtonClick(Sender: TObject);

  function ListIPs(list: TStrings): string;
  var
    i: integer;
  begin
    result := '';
    if list.count > 0 then begin
      result := list[0];
      if list.count > 1 then begin
        result := result + ', ' + list[1];
        if list.count > 2 then
          result := result + '...';
      end;
    end;
  end;

  procedure setCb(row: integer; const current: string);
  var
    v: string;
  begin
    if OptionsGrid.cells[2, row] = current then
      v := '0'
    else
      v := '1';
    OptionsGrid.cells[0, row] := v;
  end;

begin
  with OptionsGrid do begin
    cells[1, 1] := 'Subnet';
    cells[2, 1] := SubnetEdit.Text;
    setCb(1, params.subnet);

    cells[1, 2] := 'Subnet bits';
    cells[2, 2] := SubnetBitsEdit.Text;
    if SubnetBitsEdit.value = params.subnetbits then
      cells[0, 2] := '0'
    else
      cells[0, 2] := '1';

    cells[1, 3] := 'Scan';
    if FullRangeRadioButton.checked then
      cells[2, 3] := 'All IP in subnet'
    else
      cells[2, 3] := 'IP in range';
    if FullRangeRadioButton.checked = params.ScanAllIP then
      cells[0, 3] := '0'
    else
      cells[0, 3] := '1';

    cells[1, 4] := 'First IP';
    cells[2, 4] := FirstIPEdit.Text;
    setCb(4, params.FirstIP);

    cells[1, 5] := 'Last IP';
    cells[2, 5] := LastIPEdit.Text;
    setCb(5, params.LastIP);


    cells[1, 6] := 'Scan connect attempts';
    cells[2, 6] := ScanAttemptsEdit.Text;
    if ScanAttemptsEdit.value = params.ScanAttempts then
      cells[0, 6] := '0'
    else
      cells[0, 6] := '1';

    cells[1, 7] := 'Scan connect timeout';
    cells[2, 7] := ScanTimeoutEdit.Text;
    if ScanTimeOutEdit.value = params.ScanTimeout then
      cells[0, 7] := '0'
    else
      cells[0, 7] := '1';

    cells[1, 8] := 'Backup directory';
    cells[2, 8] := DirectoryEdit.Directory;
    setCb(8, params.directory);

    cells[1, 9] := 'Backup extension';
    cells[2, 9] := ExtensionEdit.Text;
    setCb(9, params.extension);

    cells[1, 10] := 'Date format';
    cells[2, 10] := DateformatEdit.Text;
    if DateformatEdit.ItemIndex = params.dateformat then
      cells[0, 10] := '0'
    else
      cells[0, 10] := '1';

    cells[1, 11] := 'Filename format';
    if radioButton1.Checked then
      cells[2, 11] := ChangeFileExt(radiobutton1.caption, '')
    else
      cells[2, 11] := ChangeFileExt(radiobutton2.caption, '');
    if (radioButton1.checked and (params.filenameformat = 0))
    or (radioButton2.checked and (params.filenameformat = 1)) then
      cells[0, 11] := '0'
    else
      cells[0, 11] := '1';

    cells[1, 12] := 'Device name';
    if radioButton3.Checked then
      cells[2, 12] := 'Topic'
    else
      cells[2, 12] := 'Hostname';
    if (radioButton3.checked and (params.devicename = 0))
    or (radioButton4.checked and (params.devicename = 1)) then
      cells[0, 12] := '0'
    else
      cells[0, 12] := '1';

    cells[1, 13] := 'Download attempts';
    cells[2, 13] := DownloadAttemptsEdit.Text;
    if DownloadAttemptsEdit.value = params.DownloadAttempts then
      cells[0, 13] := '0'
    else
      cells[0, 13] := '1';

    cells[1, 14] := 'Download timeout';
    cells[2, 14] := DownloadTimeoutEdit.Text;
    if DownloadTimeoutEdit.value = params.DownloadTimeout then
      cells[0, 14] := '0'
    else
      cells[0, 14] := '1';

    cells[1, 15] := 'Exclude IP addresses';
    cells[2, 15] := ListIPs(ExcludeListBox.Items);
    if ExcludeListBox.Items.Equals(params.ExcludeIPs) then
      cells[0, 15] := '0'
    else
      cells[0, 15] := '1';

    cells[1, 16] := 'Include IP addresses';
    cells[2, 16] := ListIPs(IncludeListBox.Items);
    if IncludeListBox.Items.Equals(params.IncludeIPs) then
      cells[0, 16] := '0'
    else
      cells[0, 16] := '1';
  end;
  Notebook1.PageIndex := 4;
  AllOptionsCheckBox.SetFocus;
end;

procedure TMainForm.Page2BeforeShow(ASender: TObject; ANewPage: TPage;
  ANewIndex: Integer);
begin
  updategrid := DeviceGrid;
end;

procedure TMainForm.Page4BeforeShow(ASender: TObject; ANewPage: TPage;
  ANewIndex: Integer);
begin
  updategrid := ResGrid;
end;

procedure TMainForm.Page5BeforeShow(ASender: TObject; ANewPage: TPage;
  ANewIndex: Integer);
begin
  updategrid := OptionsGrid;
end;

procedure TMainForm.PopupMenu1Close(Sender: TObject);
begin
  PopupMenu1.tag := 0;
end;

procedure TMainForm.PopupMenu1Popup(Sender: TObject);
begin
  PopupMenu1.tag := 1;
end;

procedure TMainForm.QuitButtonClick(Sender: TObject);
begin
  close;
end;

procedure TMainForm.ResetButtonClick(Sender: TObject);
var
  i: integer;
begin
  for i := 1 to OptionsGrid.Rowcount-1 do begin
    if OptionsGrid.cells[0, i] = '0' then
       continue;
    case i of
       1: params.Subnet := DEFAULT_SUBNET;
       2: params.SubnetBits := DEFAULT_SUBNET_BITS;
       3: params.ScanAllIP := DEFAULT_SCAN_ALL_IP;
       4: params.FirstiP := DEFAULT_FIRST_IP;
       5: params.LastIP := DEFAULT_LAST_IP;
       6: params.ScanAttempts := DEFAULT_SCAN_ATTEMPTS;
       7: params.ScanTimeout := DEFAULT_SCAN_TIMEOUT;
       8: params.Directory := DEFAULT_BACK_DIRECTORY;
       9: params.Extension := DEFAULT_EXTENSION;
      10: params.Dateformat := DEFAUT_DATE_FORMAT;
      11: params.FilenameFormat := DEFAULT_FILENAME_FORMAT;
      12: params.DeviceName := DEFAULT_DEVICE_NAME;
      13: params.DownloadAttempts := DEFAULT_DOWNLOAD_ATTEMPTS;
      14: params.DownloadTimeout := DEFAULT_DOWNLOAD_TIMEOUT;
      15: params.ExcludeIPsAction := ilaErase;
      16: params.IncludeIPsAction := ilaErase;
     end;
  end;
  close;
end;

procedure TMainForm.ResGridDblClick(Sender: TObject);
begin
  CopyResGridToClipbrd(#9);
end;

procedure TMainForm.ResGridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if (PopupMenu1.tag = 0) and (Button = mbRight) then begin
    popx := left + x;
    popy := top + y;
    PopupMenu1.PopUp(popx, popy);
  end;
end;

procedure TMainForm.SaveButtonClick(Sender: TObject);
var
  i: integer;
begin
  for i := 1 to OptionsGrid.Rowcount-1 do begin
    if OptionsGrid.cells[0, i] = '0' then
       continue;
    case i of
       1: params.Subnet := OptionsGrid.cells[2, i];
       2: params.SubnetBits := SubnetBitsEdit.value;
       3: params.ScanAllIP := FullRangeRadioButton.Checked;
       4: params.FirstIP := OptionsGrid.cells[2, i];
       5: params.LastIP := OptionsGrid.cells[2, i];
       6: params.ScanAttempts := ScanAttemptsEdit.value;
       7: params.ScanTimeout := ScanTimeoutEdit.value;
       8: params.directory := OptionsGrid.cells[2, i];
       9: params.extension := OptionsGrid.cells[2, i];
      10: params.dateformat := DateFormatEdit.ItemIndex;
      11: if RadioButton1.Checked then
            params.filenameformat := 0
          else
            params.filenameformat := 1;
      12: if RadioButton3.Checked then
            params.devicename := 0
          else
            params.devicename := 1;
      13: params.DownloadAttempts := DownloadAttemptsEdit.value;
      14: params.DownloadTimeout := DownloadTimeoutEdit.value;
      15: begin params.ExcludeIPsAction := ilaSave; params.ExcludeIPs := ExcludeListBox.Items; end;
      16: begin params.IncludeIPsAction := ilaSave; params.IncludeIPs := IncludeListBox.Items; end;
     end;
  end;
  close;
end;

procedure TMainForm.ScanAttemptsEditChange(Sender: TObject);
begin
  CalcMaxRequestTime;
  FixupAllIpHint;
  FixupIpRangeHint;
end;

procedure TMainForm.SubnetBitsEditChange(Sender: TObject);
begin
  FixupAllIpHint;
end;

procedure TMainForm.SubnetEditDone(Sender: TObject);
var
  ip, lfip, llip, mask: TIPv4;
begin
  if TryStrToIPv4(SubnetEdit.text, ip) then begin
    mask := SubnetMask(SubnetBitsEdit.value);
    if TryStrToIPv4(FirstIpEdit.text, lfip) then
      lfip := (lfip and not mask) or (ip and mask)
    else
      lfip := (ip and mask).succ;
    if TryStrToIPv4(LastIpEdit.text, llip) then
      llip := (llip and not mask) or (ip and mask)
    else
      llip := ((ip and mask) or (not mask)).pred;
    FirstIPEdit.text := lfip.ToString;
    LastIPEdit.Text := llip.ToString;
  end
end;

procedure TMainForm.UpdateCheckCount;
var
  i, checkcount: integer;
begin
  checkcount := 0;
  for i := 1 to DeviceGrid.RowCount-1 do
    if DeviceGrid.cells[0, i] = '1' then inc(checkcount);
  label11.Caption := Format('%d devices checked / %d total', [checkcount, DeviceGrid.RowCount-1]);
end;


{$IFDEF MSWINDOWS}{$IFDEF DO_LOG}
finalization
  if logopened then
    close(StdOut);
{$ENDIF}{$ENDIF}
end.

