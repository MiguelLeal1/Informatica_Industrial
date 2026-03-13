unit unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, comUnit;

type

  { TForm2 }

  TForm2 = class(TForm)
    Bconnect: TButton;
    Bunload: TButton;
    Button1: TButton;
    Button2: TButton;
    Bload: TButton;
    Bfree: TButton;
    Bused: TButton;
    Boccupation: TButton;
    Binitialize: TButton;
    Btransport: TButton;
    Breceive: TButton;
    Bcommand_status: TButton;
    BFactoryStatus: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure Bcommand_statusClick(Sender: TObject);
    procedure BconnectClick(Sender: TObject);
    procedure BfreeClick(Sender: TObject);
    procedure BinitializeClick(Sender: TObject);
    procedure BoccupationClick(Sender: TObject);
    procedure BreceiveClick(Sender: TObject);
    procedure BtransportClick(Sender: TObject);
    procedure BunloadClick(Sender: TObject);
    procedure BusedClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure BloadClick(Sender: TObject);
    procedure BFactoryStatusClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Label4Click(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private

  public

  end;

var
  Form2: TForm2;
  SeqID: integer = 500;

implementation

{$R *.lfm}

{ TForm2 }

procedure TForm2.BconnectClick(Sender: TObject);
var result : integer;
begin
        result:=M_connect();

        Memo1.append('CONNECT : Resultado = ' + floattostr(result));
end;

procedure TForm2.Bcommand_statusClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Command_Status(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' COMMAND_STATUS (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' COMMAND_STATUS : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BfreeClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Free(seqid);

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' FREE' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' FREE : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BinitializeClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Initialize(seqid, strtoint(Edit1.text), strtoint(Edit2.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' INITIALIZE (' + Edit1.text +', ' + Edit2.text +')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' INITIALIZE : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BoccupationClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Occupation(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' OCCUPATION (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' OCCUPATION : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BreceiveClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Receive(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' RECEIVE (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' RECEIVE : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BtransportClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Transport(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' TRANSPORT (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' TRANSPORT : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BunloadClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Unload(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' UNLOAD (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' UNLOAD : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;

end;

procedure TForm2.BusedClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_Used(seqid);

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' USED' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' USED : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.Button1Click(Sender: TObject);
var result : integer;
begin
        result:=M_connect();

        Memo1.append('DISCONNECT : Resultado = ' + floattostr(result));

        seqid:=500;

end;

procedure TForm2.Button2Click(Sender: TObject);
begin
     ComForm1.Show;
end;

procedure TForm2.BloadClick(Sender: TObject);
var result: cmd_result;
begin
     result:=M_load(seqid, strtoint(Edit1.text));

     Memo1.append('SEQID #'+ floattostr(seqid)+ ' LOAD (' + Edit1.text + ')' );
     Memo1.append('SEQID #'+ floattostr(result.seqid)+ ' LOAD : Resultado = ' + floattostr(result.result));

     seqid:=seqid+1;
end;

procedure TForm2.BFactoryStatusClick(Sender: TObject);
var
  i: integer;
begin
     Memo2.clear;
     for i:=0 to 11 do
         Memo2.append('('+floattostr(i)+') = ' + floattostr(status_values[i]));


end;

procedure TForm2.FormCreate(Sender: TObject);
begin

end;

procedure TForm2.Label4Click(Sender: TObject);
begin

end;

procedure TForm2.Memo1Change(Sender: TObject);
begin

end;

end.

