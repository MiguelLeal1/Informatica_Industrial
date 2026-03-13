unit comUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Buttons, tcp_udpport, commtypes, PLCBlock, PLCBlockElement, ModBusTCP, Tag, crt;

const

status_response_size = 8;

M_cmd_msg: array [-115 .. -100] of string =
  (
  'No parts avaliable',
  'Sequence ID out of range',
  'Failed part at expedition',
  'Unable to receive parts',
  'Part mismatch error',
  'Destination error',
  'Warehouse is busy',
  'Initialize range error',
  'Part mismatch error',
  'No part at the warehouse output',
  'Part at the warehouse output',
  'No part at the warehouse entry',
  'Warehouse position out of range',
  'Warehouse position is empty',
  'Warehouse position is not empty',
  'General error'
  );

M_status_msg: array [1..status_response_size] of string =
  ('FactoryIO state',
   'Inbound state',
   'Warehouse_state',
   'Warehouse input conveyor part',
   'Warehouse output conveyor part',
   'Cell 1 part',
   'Cell 2 part',
   'Pick & Place part'
   );


type

  status_values = array[1..status_response_size] of integer;

  cmd_result = record
      seqid: integer;
      result: integer;
  end;



  { TComForm }

  TComForm = class(TForm)
    Cmd_data_e0: TPLCBlockElement;
    Cmd_R: TPLCBlock;
    Cmd_data: TPLCBlock;
    Label1: TLabel;
    ModBusTCPDriver1: TModBusTCPDriver;
    Splitter1: TSplitter;
    TCP_UDPPort1: TTCP_UDPPort;
    procedure Cmd_RAsyncValueChange(Sender: TObject; const Value: TArrayOfDouble
      );
    procedure FormCreate(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label2Click(Sender: TObject);
    procedure Label3Click(Sender: TObject);
    procedure Memo3Change(Sender: TObject);
    procedure RPieceChange(Sender: TObject);
    procedure Memo2Change(Sender: TObject);
    procedure Cmd_dataAsyncValueChange(Sender: TObject;
      const Value: TArrayOfDouble);
    procedure Cmd_dataUpdate(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
    procedure Status_RAsyncValueChange(Sender: TObject;
      const Value: TArrayOfDouble);
    procedure Status_RValueChange(Sender: TObject);
    procedure TCP_UDPPort1CommErrorReading(Error: TIOResult);
    procedure TCP_UDPPort1CommPortDisconnected(Sender: TObject);
    procedure TCP_UDPPort1CommPortOpened(Sender: TObject);
    procedure TCP_UDPPort1CommPortOpenError(Sender: TObject);

  private

  public

  end;

  function M_Connect(): integer;
  function M_Disconnect(): integer;
  function M_Load(position: integer): integer;
  function M_Unload(position: integer): integer;
  function M_Get_Free(): integer;
  function M_Get_Stored(piece: integer): integer;
  function M_Get_Part_Info(position: integer): integer;
  function M_Initialize(position, piece: integer): integer;
  function M_Do_Production(destination: integer): integer;
  function M_Do_Inbound (piece: integer): integer;
  function M_Get_Factory_Status(): status_values;
  function M_Set_Part_Defect(piece, number : integer): integer;
  function M_Get_Part_Quality(position: integer): integer;
  function M_Do_Expedition(destination: integer): integer;
  function M_Do_Scratch (piece: integer): integer;
  function M_Connection_Status(): integer;

var
  ComForm: TComForm;





implementation
const
cmd_values_size = 5;
cmd_responde_size = 5;
isError=100;


var
  cmd_values: array[0..4] of double;
  cmd_response: array[0..4] of double;
  connection_status: integer = 0;
  sequenceID: integer =1;

{$R *.lfm}

function M_Connection_Status(): integer;
begin
    M_Connection_Status:= connection_status;
end;



function M_Connect(): integer;
begin
  if (ComForm.TCP_UDPPort1.Active=false) then
    begin
     ComForm.TCP_UDPPort1.Active:=true;
     M_Connect:=1;
    end
  else
    M_Connect:=-1;

end;

function M_Disconnect(): integer;
begin
  if (ComForm.TCP_UDPPort1.Active=true) then
    begin
     ComForm.TCP_UDPPort1.Active:=False;
     M_Disconnect:=1;
     end
 else
     M_Disconnect:=-1;
 end;

function M_Get_Factory_Status(): status_values;
var i : integer;
begin
      ComForm.Cmd_R.Read();
      sleep(200);
      for i:=1 to status_response_size do
          M_Get_factory_Status[i]:=round(ComForm.Cmd_R.ValuesRaw[cmd_responde_size+i-1]);

 end;

function M_Load(position: integer): integer;
var aux : integer;
begin
  if (position >=0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=1;
         cmd_values[2]:=position;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
            M_Load:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
            M_Load:=aux;
    end
    else
    begin
        M_Load:=-1;
    end;
end;

function M_Unload(position: integer): integer;
var aux : integer;
begin
  if (position >0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=2;
         cmd_values[2]:=position;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
          if (aux =isError) then
             M_Unload:=-round(ComForm.Cmd_R.ValuesRaw[1])
          else
             M_Unload:=aux;
    end
    else
    begin
        M_Unload:=-1;
    end;
end;

function M_Get_Free(): integer;
var aux : integer;
begin
     sequenceID:=sequenceID+1;
     cmd_values[0]:=sequenceID;
     cmd_values[1]:=3;
     cmd_values[2]:=0;
     cmd_values[3]:=0;
     cmd_values[4]:=0;
     ComForm.Cmd_data.Write(cmd_values,5,0);

     sleep(200);
     ComForm.Cmd_R.Read();

     aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
     if (aux =isError) then
          M_Get_Free:=-round(ComForm.Cmd_R.ValuesRaw[1])
     else
         M_Get_Free:=aux;
end;

function M_Get_Stored(piece: integer): integer;
var aux : integer;
begin
  if (piece >= 0)then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=4;
         cmd_values[2]:=piece;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Get_Stored:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Get_Stored:=aux;
    end
    else
    begin
        M_Get_Stored:=-1;
    end;
end;

function M_Get_Part_Info(position: integer): integer;
var aux : integer;
begin
  if (position >=0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=5;
         cmd_values[2]:=position;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Get_Part_Info:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Get_Part_Info:=aux;
    end
    else
    begin
        M_Get_Part_Info:=-1;
    end;
end;

function M_Initialize(position, piece: integer): integer;
var aux : integer;
begin
  if ((position >=0) and (piece >= 0)) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=6;
         cmd_values[2]:=position;
         cmd_values[3]:=piece;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Initialize:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Initialize:=aux;

    end
    else
    begin
        M_Initialize:=-1;
    end;
end;

function M_Do_Production(destination: integer): integer;
var aux : integer;
begin
  if (destination >0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=10;
         cmd_values[2]:=destination;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Do_Production:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Do_Production:=aux;
    end
    else
    begin
        M_Do_Production:=-1;
    end;
end;

function M_Do_Expedition(destination: integer): integer;
var aux : integer;
begin
  if (destination >0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=11;
         cmd_values[2]:=destination;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Do_Expedition:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Do_Expedition:=aux;
    end
    else
    begin
        M_Do_Expedition:=-1;
    end;
end;

function M_Do_Inbound(piece: integer): integer;
var aux : integer;
begin
  if (piece >=0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=8;
         cmd_values[2]:=piece;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Do_Inbound:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Do_Inbound:=aux;
    end
    else
    begin
        M_Do_Inbound:=-1;
    end;
end;

function M_Get_Command_Status(): integer;
var aux : integer;
begin
       sequenceID:=sequenceID+1;
       cmd_values[0]:=sequenceID;
       cmd_values[1]:=9;
       cmd_values[2]:=0;
       cmd_values[3]:=0;
       cmd_values[4]:=0;
       ComForm.Cmd_data.Write(cmd_values,5,0);
       sleep(200);
       ComForm.Cmd_R.Read();
       aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
       if (aux =isError) then
            M_Get_Command_Status:=-round(ComForm.Cmd_R.ValuesRaw[1])
       else
           M_Get_Command_Status:=aux;
end;

function M_Set_Part_Defect(piece, number : integer): integer ;
var aux : integer;
begin
  if ((piece >0) and (number >0)) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=12;
         cmd_values[2]:=piece;
         cmd_values[3]:=number;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Set_Part_Defect:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Set_Part_Defect:=aux;
    end
    else
      begin
          M_Set_Part_Defect:=-1;
      end;

end;

function M_Get_Part_Quality(position: integer): integer ;
var aux : integer;
begin
  if (position >0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=13;
         cmd_values[2]:=position;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Get_Part_Quality:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Get_Part_Quality:=aux;
    end
    else
      begin
          M_Get_Part_Quality:=-1;
      end;
end;


function M_Do_Scratch (piece: integer): integer;
var aux : integer;
begin
  if (piece >0) then
    begin
         sequenceID:=sequenceID+1;
         cmd_values[0]:=sequenceID;
         cmd_values[1]:=14;
         cmd_values[2]:=piece;
         cmd_values[3]:=0;
         cmd_values[4]:=0;
         ComForm.Cmd_data.Write(cmd_values,5,0);
         sleep(200);
         ComForm.Cmd_R.Read();
         aux:=round(ComForm.Cmd_R.ValuesRaw[0]);
         if (aux =isError) then
              M_Do_Scratch:=-round(ComForm.Cmd_R.ValuesRaw[1])
         else
             M_Do_Scratch:=aux;
    end
    else
      begin
          M_Do_Scratch:=-1;
      end;
end;

{ TComForm }


procedure TComForm.TCP_UDPPort1CommErrorReading(Error: TIOResult);
begin

end;

procedure TComForm.TCP_UDPPort1CommPortDisconnected(Sender: TObject);
begin
    Label1.Caption:='Disconnected';
    connection_status:=0;
end;

procedure TComForm.TCP_UDPPort1CommPortOpened(Sender: TObject);
begin
     Label1.Caption:='Connection OK';
     connection_status:=1;
end;

procedure TComForm.TCP_UDPPort1CommPortOpenError(Sender: TObject);
begin
     Label1.Caption:='Connection error';
    connection_status:=-1;
end;


procedure TComForm.FormCreate(Sender: TObject);
begin

end;

procedure TComForm.Cmd_RAsyncValueChange(Sender: TObject;
  const Value: TArrayOfDouble);
begin

end;

procedure TComForm.Label1Click(Sender: TObject);
begin

end;

procedure TComForm.Label2Click(Sender: TObject);
begin

end;

procedure TComForm.Label3Click(Sender: TObject);
begin

end;

procedure TComForm.Memo3Change(Sender: TObject);
begin

end;

procedure TComForm.RPieceChange(Sender: TObject);
begin

end;

procedure TComForm.Memo2Change(Sender: TObject);
begin

end;

procedure TComForm.Cmd_dataAsyncValueChange(Sender: TObject;
  const Value: TArrayOfDouble);
begin

end;

procedure TComForm.Cmd_dataUpdate(Sender: TObject);
var i : integer;
begin
  for i:=0 to 4 do
  cmd_response[i]:=round(Cmd_R.ValuesRaw[i]);

end;

procedure TComForm.Memo1Change(Sender: TObject);
begin

end;

procedure TComForm.Status_RAsyncValueChange(Sender: TObject;
  const Value: TArrayOfDouble);
begin


end;


procedure TComForm.Status_RValueChange(Sender: TObject);
begin

end;

end.

