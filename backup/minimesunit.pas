unit miniMESunit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  comUnit;

type

  { TFormMiniMES }

  TFormMiniMES = class(TForm)
    Bconnect: TButton;
    Bset_part_defect: TButton;
    Bget_part_quality: TButton;
    Bdo_expedition: TButton;
    Bdo_scratch: TButton;
    Bunload: TButton;
    BDisconnect: TButton;
    Bload: TButton;
    Bget_free: TButton;
    Bget_stored: TButton;
    Bget_part_info: TButton;
    Binitialize: TButton;
    Bdo_production: TButton;
    Bdo_inbound: TButton;
    Button1: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    Timer1: TTimer;
    procedure Bdo_expeditionClick(Sender: TObject);
    procedure Bdo_scratchClick(Sender: TObject);
    procedure BconnectClick(Sender: TObject);
    procedure Bget_freeClick(Sender: TObject);
    procedure Bget_part_qualityClick(Sender: TObject);
    procedure BinitializeClick(Sender: TObject);
    procedure Bget_part_infoClick(Sender: TObject);
    procedure Bdo_inboundClick(Sender: TObject);
    procedure Bdo_productionClick(Sender: TObject);
    procedure Bset_part_defectClick(Sender: TObject);
    procedure BunloadClick(Sender: TObject);
    procedure Bget_storedClick(Sender: TObject);
    procedure BDisconnectClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure BloadClick(Sender: TObject);
    procedure Bget_factory_statusClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Label5Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

procedure Print_Factory_Status();

var
  FormMiniMES: TFormMiniMES;

implementation

{$R *.lfm}

{ TFormMiniMES }

procedure TFormMiniMES.BconnectClick(Sender: TObject);
var result : integer;
var msg : string;
begin
        result:=M_connect();

        if (result = 1) then
           msg:=' Connected'
        else
           msg:=' Connnection error';


        Memo1.append('CONNECT : R = [' + floattostr(result)+ '] '+ msg);
end;

procedure TFormMiniMES.Bdo_expeditionClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Do_Expedition(strtoint(Edit1.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('DO_EXPEDITION : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bdo_scratchClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Do_Scratch(strtoint(Edit1.text));

     case r of
          1..52: msg:='Scratch from position = ' + floattostr(r);
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('DO_SCRATCH : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bget_freeClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Get_Free();

     case r of
          0..52: msg:='Number of postions free = '+floattostr(r);
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('GET_FREE : --> '+
     'R = ['+ floattostr(r)+'] '+ msg);
end;

procedure TFormMiniMES.Bget_part_qualityClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Get_Part_Quality(strtoint(Edit1.text));

     case r of
          1: msg:='Part has quality';
          2: msg:='Part has a defect';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('GET_PART_QUALITY : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);
end;

procedure TFormMiniMES.BinitializeClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Initialize(strtoint(Edit1.text), strtoint(Edit2.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('INITIALIZE : [' + Edit1.text + '] [' + Edit2.Text + '] --> '+
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bget_part_infoClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Get_Part_Info(strtoint(Edit1.text));

     case r of
          1..9: msg:='Part = ' + floattostr(r);
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('GET_PART_INFO : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bdo_inboundClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Do_Inbound(strtoint(Edit1.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('DO_INBOUND : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bdo_productionClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Do_Production(strtoint(Edit1.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('DO_PRODUCTION : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bset_part_defectClick(Sender: TObject);
var r: integer;
var msg : string;
begin

  r:=M_Set_Part_Defect(strtoint(Edit1.text), strtoint(Edit2.text));

  case r of
       1: msg:='OK';
       100..115: msg:=M_cmd_msg[r];
       255: msg:='Invalid Command';
  end;

  Memo1.append('SET_PART_DEFECT : [' + Edit1.text + '] [' + Edit2.text + '] --> ' +
  'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.BunloadClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Unload(strtoint(Edit1.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('UNLOAD : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);

end;

procedure TFormMiniMES.Bget_storedClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_Get_Stored(strtoint(Edit1.text));

     case r of
          0..52: msg:='Number of stored parts = ' + floattostr(r);
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('GET_STORED : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);
end;

procedure TFormMiniMES.BDisconnectClick(Sender: TObject);
var r: integer;
var msg : string;
begin
        r:=M_Disconnect();

        if (r = 1) then
           msg := ' Disconnected'
        else
           msg := ' Disconnect error';


        Memo1.append('DISCONNECT : R =[' + floattostr(r) + '] '+msg);


end;

procedure TFormMiniMES.Button1Click(Sender: TObject);

begin
     Memo1.clear;
end;


procedure TFormMiniMES.BloadClick(Sender: TObject);
var r: integer;
var msg : string;
begin
     r:=M_load(strtoint(Edit1.text));

     case r of
          1: msg:='OK';
          100..115: msg:=M_cmd_msg[r];
          255: msg:='Invalid Command';
     end;

     Memo1.append('LOAD : [' + Edit1.text + '] --> ' +
     'R = ['+ floattostr(r)+'] '+ msg);
end;

procedure TFormMiniMES.Bget_factory_statusClick(Sender: TObject);
begin
     Print_Factory_Status();

end;

procedure Print_Factory_Status();
var
  i: integer;
  r: status_values;
begin
     r:=M_Get_Factory_Status();

     FormMiniMES.Memo2.clear;
     for i:=1 to status_response_size do
         FormMiniMES.Memo2.append('['+floattostr(i)+'] ' + M_status_msg[i]+'='+floattostr(r[i]));

end;

procedure TFormMiniMES.FormCreate(Sender: TObject);
begin

end;

procedure TFormMiniMES.Label4Click(Sender: TObject);
begin

end;

procedure TFormMiniMES.Label5Click(Sender: TObject);
begin

end;

procedure TFormMiniMES.Memo1Change(Sender: TObject);
begin

end;

procedure TFormMiniMES.Timer1Timer(Sender: TObject);
var i: integer;
var r: status_values;
begin
  if (M_Connection_Status() = 1) then
     Label5.Caption:='Connection OK';

  if (M_Connection_Status() = -1) then
      Label5.Caption:='Connection Error';

    if (M_Connection_Status() = 0) then
      Label5.Caption:='No Connection';

    r:=M_Get_Factory_Status();

    Print_Factory_Status();
end;

end.

