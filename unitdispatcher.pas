unit unitdispatcher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  Grids, comUnit;

type

  //***************************************
  //Production plan obtained by ERP and available in the DB
  // Enumerated: defines the type of the TTask
  TTask_Type  = (Type_Expedition = 1, Type_Delivery, Type_Production, Type_Trash);

  // TBC by a Query to DB
  TProduction_Order = record
    part_type           : Integer;    // Part type { 0, ... 9}
    part_numbers        : Integer;    // Number of parts to be performed
    order_type          : TTask_Type;
  end;

  TArray_Production_Order = array of TProduction_Order; // This array shall be completed by the SQL query
  //***************************************



  //***************************************
  // Dispatcher Execution
  // Enumerated: defines all stages of TTasks
  TStage      = (Stage_To_Be_Started = 1, Stage_GetPart,Stage_Load, Stage_Unload,Stage_To_AR_In, Stage_To_AR_Out, Stage_Clear_Pos_AR, Stage_Finished);   //TbC

  // Data structure for holding one Task (OE, OD, OP)
  TTask = record
   task_type           : TTask_Type; // type
   current_operation   : TStage;     // the stage that is currently activ.
   part_type           : Integer;    // Part type { 0, ... 9}
   part_position_AR    : Integer;    // Part Position in AR (if needed)
   part_destination    : Integer;    // Part destination
  end;

  TArray_Task = array of TTask;      // NOTE: this "type" will originate a variable to hold the output from the scheduling ("sequenciador").
  //***************************************


  //***************************************
  // Availability of the resources in the shopfloor:
  TResources = record
   AR_free      : Boolean;    // true (free) or false (busy)
   AR_In_Part   : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   AR_Out_Part  : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_1_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_2_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Inbound_free : Boolean;    // true (free) or false (busy)
  end;
  //***************************************



  { TFormDispatcher }
  TFormDispatcher = class(TForm)
    BtnIniciarPlano: TButton;
    BStart: TButton;
    BExecute: TButton;
    BAdicionarOrdem: TButton;
    BLimparPlano: TButton;
    BInitialize: TButton;
    BAdicionarPecaWarehouse: TButton;
    CmbTipoOrdem: TComboBox;
    CmbTipoPeca: TComboBox;
    CmbTipoPecaWarehouse: TComboBox;
    EditQuantidadeWarehouse: TEdit;
    EditQuantidade: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Memo1: TMemo;
    GridPlanoProducao: TStringGrid;
    GridProducaoRealizada: TStringGrid;
    LabelTipoDePeca: TStaticText;
    QuantidadeDaPecaAAdicionar: TStaticText;
    GridEstadoArmazem: TStringGrid;
    EstadoArmazem: TStaticText;
    Timer1: TTimer;
    procedure BAdicionarOrdemClick(Sender: TObject);
    procedure BAdicionarPecaWarehouseClick(Sender: TObject);
    procedure BExecuteClick(Sender: TObject);
    procedure BIniciarPlano(Sender: TObject);
    procedure BLimparPlanoClick(Sender: TObject);
    procedure BStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private

  public
    procedure Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
    procedure Execute_Expedition_Order(var task:TTask; shopfloor: TResources );
    procedure Execute_Production_Order(var task:TTask; shopfloor: TResources );
    procedure Execute_Inbound_Order(var task:TTask; shopfloor: TResources );
    function GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
    procedure SET_AR_Position (idx : integer; Part : integer; var Warehouse : array of integer);

  end;

const
  //ID for Parts to be used by FIO
  Part_Raw_Blue   = 1;
  Part_Raw_Green  = 2;
  Part_Raw_Grey   = 3;
  Part_Base_Blue  = 4;
  Part_Base_Green = 5;
  Part_Base_Grey  = 6;
  Part_Lid_Blue   = 7;
  Part_Lid_Green  = 8;
  Part_Lid_Grey   = 9;


(* GLOBAL VARIABLES *)
var
  FormDispatcher : TFormDispatcher;

  // Production orders obtained by the ERP (using the SQL Query)
  Production_Orders : TArray_Production_Order;

  // Availability of resources (needs to be updated over time)
  ShopResources : TResources;

  // Tasks that need to be concluded by the MES (expedition, delivery, production and trash).
  ShopTasks     : TArray_Task;

  // Index of the task (from the array "ShopTasks") that is being executed.
  idx_Task_Executing : integer;

  // Status of each cell in the warehouse.
  WAREHOUSE_Parts           : array of integer;         //warehouse parts in each position

implementation

{$R *.lfm}


{ Procedure that checks the status of the resources available on the shop floor }
procedure UpdateResources(var shopfloor: TResources);
var
    resp : array[1..8] of integer;
begin
  {'FactoryIO state',
   'Inbound state',
   'Warehouse_state',
   'Warehouse input conveyor part',
   'Warehouse output conveyor part',
   'Cell 1 part',
   'Cell 2 part',
   'Pick & Place part'
   }
  resp:=M_Get_Factory_Status();

  with shopfloor do
  begin
    Inbound_free := Int(resp[2]) = 1;
    AR_free      := Int(resp[3]) = 1;
    AR_In_Part   := LongInt(resp[4]);
    AR_Out_Part  := LongInt(resp[5]);
    Robot_1_Part := LongInt(resp[6]);
    Robot_2_Part := LongInt(resp[7]);
  end;
end;


{ Procedure that received TArray_Production_Order and converts to TArray_Task
-> INPUT: TArray_Production_Order
-> OUTPUT: TArray_Task
}
procedure SimpleScheduler(var orders: TArray_Production_Order; var tasks:TArray_Task );
var
    current_task     : TTask;
    idx_order        : integer;
    numb_tasks_total : integer = 0;       // total number of tasks created in "tasks"
    numb_same_task   : integer = 0;

begin
  for idx_order:= 0 to Length(orders)-1 do
  begin
      with current_task do
      begin
        numb_same_task    := 0;

        task_type         := orders[idx_order].order_type;
        part_type         := orders[idx_order].part_type;
        current_operation := Stage_To_Be_Started;

        part_position_AR  := -1;  // to be defined later.   STUDENTS MUST CHANGE

        if( part_type < Part_Lid_Blue )then
        begin
             part_destination  := 1;     // if bases (Exit 1 or Cell 1)
        end else
        begin
            part_destination  := 2;     // if bases (Exit 2 or Cell 2)
        end;

        //Create  orders[idx_order].part_numbers of the same TTask for Dispatcher.
        numb_tasks_total :=  Length(tasks);
        SetLength(tasks,  numb_tasks_total + orders[idx_order].part_numbers);
        for numb_same_task := 0 to orders[idx_order].part_numbers-1 do
        begin
            tasks[numb_tasks_total+numb_same_task] := current_task;
        end;
      end;
  end;

end;


procedure TFormDispatcher.FormCreate(Sender: TObject);
begin
  SetLength(ShopTasks, 0);
  idx_Task_Executing := 0;

  // Preenche a ComboBox com os nomes das peças
  CmbTipoPecaWarehouse.Items.Add('Matéria-Prima Azul');    // índice 0 -> peça 1
  CmbTipoPecaWarehouse.Items.Add('Matéria-Prima Verde');   // índice 1 -> peça 2
  CmbTipoPecaWarehouse.Items.Add('Matéria-Prima Metal');   // índice 2 -> peça 3
  CmbTipoPecaWarehouse.Items.Add('Base Azul');             // índice 3 -> peça 4
  CmbTipoPecaWarehouse.Items.Add('Base Verde');            // índice 4 -> peça 5
  CmbTipoPecaWarehouse.Items.Add('Base Metal');            // índice 5 -> peça 6
  CmbTipoPecaWarehouse.Items.Add('Tampa Azul');            // índice 6 -> peça 7
  CmbTipoPecaWarehouse.Items.Add('Tampa Verde');           // índice 7 -> peça 8
  CmbTipoPecaWarehouse.Items.Add('Tampa Metal');           // índice 8 -> peça 9

  // Configura a grelha de estado do armazém
  GridEstadoArmazem.ColCount        := 2;
  GridEstadoArmazem.RowCount        := 1;  // só cabeçalho por agora
  GridEstadoArmazem.FixedRows       := 1;
  GridEstadoArmazem.FixedCols       := 0;
  GridEstadoArmazem.ColWidths[0]    := 100;
  GridEstadoArmazem.ColWidths[1]    := 150;
  GridEstadoArmazem.Cells[0, 0]     := 'Posição';
  GridEstadoArmazem.Cells[1, 0]     := 'Peça';
end;


procedure TFormDispatcher.Timer1Timer(Sender: TObject);
begin
  BExecuteClick(Self);
end;


procedure TFormDispatcher.BStartClick(Sender: TObject);
var
  result : integer;
begin
  idx_Task_Executing := 0;

  result := M_connect();

  if (result = 1) then
    BStart.Caption := 'Connected to PLC'
  else
  begin
    BStart.Caption := 'Start';
    ShowMessage('PLC unavailable. Please try again!');
  end;
end;

 procedure TFormDispatcher.BIniciarPlano(Sender: TObject);
  begin
  // Converte as ordens em tarefas e arranca o dispatcher
  if Length(Production_Orders) = 0 then
    begin
      ShowMessage('Não existe nenhuma ordem no plano de produção!');
      Exit;
  end;
  SimpleScheduler(Production_Orders, ShopTasks);
  Timer1.Enabled := True;
end;

 procedure TFormDispatcher.BAdicionarPecaWarehouseClick(Sender: TObject);
 const
   // As 6 posições válidas do armazém (1ª coluna)
   VALID_POS : array[0..5] of integer = (1, 10, 19, 28, 37, 46);
 var
   part      : integer;
   qty       : integer;
   i, j      : integer;
   pos       : integer;
   found     : boolean;
   nomePeca  : string;
   row       : integer;
 begin
   // Validação: peça selecionada?
   if CmbTipoPecaWarehouse.ItemIndex = -1 then
   begin
     ShowMessage('Selecione o tipo de peça!');
     Exit;
   end;

   // Validação: quantidade válida?
   qty := StrToIntDef(EditQuantidadeWarehouse.Text, 0);
   if qty <= 0 then
   begin
     ShowMessage('Introduza uma quantidade válida!');
     Exit;
   end;

   // Converte índice da ComboBox para código da peça (índice 0 = peça 1)
   part     := CmbTipoPecaWarehouse.ItemIndex + 1;
   nomePeca := CmbTipoPecaWarehouse.Items[CmbTipoPecaWarehouse.ItemIndex];

   // Inicializa o array se ainda não foi criado
   if Length(WAREHOUSE_Parts) = 0 then
   begin
     SetLength(WAREHOUSE_Parts, 55);
     for i := 0 to 54 do
       WAREHOUSE_Parts[i] := 0;
   end;

   // Tenta colocar 'qty' peças nas posições livres
   for j := 1 to qty do
   begin
     // Procura a próxima posição válida que esteja livre
     found := false;
     for i := 0 to 5 do
     begin
       pos := VALID_POS[i];
       if WAREHOUSE_Parts[pos] = 0 then  // posição livre!
       begin
         found := true;
         Break;
       end;
     end;

     if not found then
     begin
       ShowMessage('Não há posições livres no armazém!');
       Exit;
     end;

     // Guarda no array interno
     WAREHOUSE_Parts[pos] := part;

     // Envia o comando ao autómato
     if M_Initialize(pos, part) < 0 then
       Memo1.Append('Erro ao inicializar posição ' + IntToStr(pos))
     else
       Memo1.Append('Posição ' + IntToStr(pos) + ' <- ' + nomePeca);

     // Atualiza a grelha de estado
     row := GridEstadoArmazem.RowCount;
     GridEstadoArmazem.RowCount      := row + 1;
     GridEstadoArmazem.Cells[0, row] := IntToStr(pos);
     GridEstadoArmazem.Cells[1, row] := nomePeca;

     Sleep(1500);
   end;

   // Limpa os campos
   CmbTipoPecaWarehouse.ItemIndex   := -1;
   EditQuantidadeWarehouse.Text     := '';
 end;
{
 ## Como funciona a lógica de posições automáticas

 Utilizador escolhe: Tampa Verde, quantidade 2
               ↓
 Código verifica VALID_POS = [1, 10, 19, 28, 37, 46]
               ↓
 Posição 1 está livre? → Sim → coloca Tampa Verde na posição 1
 Posição 10 está livre? → Sim → coloca Tampa Verde na posição 10
               ↓
 Grelha de estado mostra:
   Posição 1  | Tampa Verde
   Posição 10 | Tampa Verde
}
procedure TFormDispatcher.BAdicionarOrdemClick(Sender: TObject);
var
  ordem      : TTask_Type;
  peca       : integer;
  quantidade : integer;
  row        : integer;
  nomeOrdem  : string;
  nomePeca   : string;
begin
  if CmbTipoOrdem.ItemIndex = -1 then
  begin
    ShowMessage('Selecione o tipo de ordem!');
    Exit;
  end;

  if CmbTipoPeca.ItemIndex = -1 then
  begin
    ShowMessage('Selecione o tipo de peca!');
    Exit;
  end;

  quantidade := StrToIntDef(EditQuantidade.Text, 0);
  if quantidade <= 0 then
  begin
    ShowMessage('Introduza uma quantidade valida!');
    Exit;
  end;

  nomeOrdem := CmbTipoOrdem.Items[CmbTipoOrdem.ItemIndex];
  nomePeca  := CmbTipoPeca.Items[CmbTipoPeca.ItemIndex];

  case CmbTipoOrdem.ItemIndex of
    0: ordem := Type_Expedition;
    1: ordem := Type_Production;
    2: ordem := Type_Delivery;
  end;

  peca := CmbTipoPeca.ItemIndex + 1;

  // Adicionar à grelha
  row := GridPlanoProducao.RowCount;
  GridPlanoProducao.RowCount := row + 1;
  GridPlanoProducao.Cells[0, row] := nomeOrdem;
  GridPlanoProducao.Cells[1, row] := nomePeca;
  GridPlanoProducao.Cells[2, row] := IntToStr(quantidade);

  // Adicionar ao array Production_Orders
  SetLength(Production_Orders, Length(Production_Orders) + 1);
  Production_Orders[Length(Production_Orders) - 1].order_type   := ordem;
  Production_Orders[Length(Production_Orders) - 1].part_type    := peca;
  Production_Orders[Length(Production_Orders) - 1].part_numbers := quantidade;

  // Limpar os campos
  CmbTipoOrdem.ItemIndex := -1;
  CmbTipoPeca.ItemIndex  := -1;
  EditQuantidade.Text    := '';

  Memo1.Append('Ordem adicionada: ' + nomeOrdem + ' | ' + nomePeca + ' | ' + IntToStr(quantidade));
end;


procedure TFormDispatcher.BLimparPlanoClick(Sender: TObject);
var
  i : integer;
begin
  SetLength(Production_Orders, length(Production_Orders) - 1);

  GridPlanoProducao.RowCount := GridPlanoProducao.RowCount- 1;

  for i := 0 to 2 do
    GridPlanoProducao.Cells[i, GridPlanoProducao.RowCount ] := '';

  CmbTipoOrdem.ItemIndex := -1;
  CmbTipoPeca.ItemIndex  := -1;
  EditQuantidade.Text    := '';

  Memo1.Append('Última operação anulada.');
end;


// get the first position (cell) in AR that contains the "Part"
function TFormDispatcher.GET_AR_Position (Part : integer; Warehouse : array of integer): integer;
var
    i : integer;
begin
  for i := 0 to Length(Warehouse)-1 do
  begin
      if Warehouse[i] = Part then
      begin
          result := i;
          Exit;
      end;
  end;
end;

//Sets the Position of the AR with the "Part" provided
procedure TFormDispatcher.SET_AR_Position (idx : integer; Part : integer; var Warehouse : array of integer);
begin
  Warehouse [ idx ] := Part;
end;


procedure TFormDispatcher.BExecuteClick(Sender: TObject);
begin
  UpdateResources(ShopResources);

  // Linha de debug - apaga depois de resolver o problema
  Memo1.Append('Ciclo: tasks=' + IntToStr(Length(ShopTasks)) +
               ' idx=' + IntToStr(idx_Task_Executing));

  if(Length(ShopTasks) > 0) then begin
    Dispatcher(ShopTasks, idx_Task_Executing, ShopResources);
  end;
end;


// Global Dispatcher - SIMPLEX
procedure TFormDispatcher.Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
begin
    case tasks[idx].task_type of

      // Expedition
      Type_Expedition :
      begin
        if(idx < Length(tasks)) then
        begin
          Memo1.Append('Task Expedition');
          Execute_Expedition_Order(tasks[idx], shopfloor);

          // Next Operation to be executed.
          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;

      // Production
      Type_Production :
      begin
        if(idx < Length(tasks)) then
        begin
          Memo1.Append('Task Production');
          Execute_Production_Order(tasks[idx], shopfloor);

          // Next Operation to be executed.
          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;

      // Inbound
      Type_Delivery :
      begin
        if(idx < Length(tasks)) then
        begin
          Memo1.Append('Task Inbound');
          Execute_Inbound_Order(tasks[idx], shopfloor);

          // Next Operation to be executed.
          if(tasks[idx].current_operation = Stage_Finished) then
            inc(idx_Task_Executing);
        end;
      end;

      // Trash
      Type_Trash :
      begin
        //todo
      end;

    end;
end;


// Procedure that executes an expedition order according to SLIDE 19 of T classes.
procedure TFormDispatcher.Execute_Expedition_Order(var task:TTask; shopfloor: TResources );
var
    r : integer;
    row : integer;
begin
  //  TStage      = (Stage_To_Be_Started = 1, Stage_GetPart, Stage_Unload, Stage_To_AR_Out, Stage_Clear_Pos_AR, Stage_Finished);   //TbC

  with task do
  begin
     case current_operation of

        // To be Started
        Stage_To_Be_Started:
        begin
           current_operation :=  Stage_GetPart;
        end;

        // Getting a Position from the Warehouse
        Stage_GetPart :
        begin
          if(shopfloor.AR_free) then  //AR is free
          begin
            Part_Position_AR := GET_AR_Position(Part_Type, WAREHOUSE_Parts);
            Memo1.Append(IntToStr(Part_Position_AR));

            if( Part_Position_AR > 0 ) then
            begin
               current_operation :=  Stage_Unload;
            end
            else
            begin
               current_operation :=  Stage_GetPart;
            end;
          end;
        end;

        // Request to unload that part
        Stage_Unload :
        begin
          Memo1.Append('AR Unloading: ' + IntToStr(Part_Position_AR));
          r := M_Unload(Part_Position_AR);

          if ( r = 1 ) then                                 //sucess
             current_operation :=  Stage_To_AR_Out;
        end;

        // Part is in the output conveyor
        Stage_To_AR_Out :
        begin
          if( ShopResources.AR_Out_Part  = Part_Type ) then
          begin
            r := M_Do_Expedition(Part_Destination);          // Expedition

            if( r = 1) then                                  // sucess
             current_operation :=  Stage_Clear_Pos_AR;
          end;
        end;

        //Updated AR (removing the part from the position)
        Stage_Clear_Pos_AR :
        begin
          SET_AR_Position(Part_Position_AR, 0, WAREHOUSE_Parts);
          current_operation :=  Stage_Finished;
        end;

        //Done.
        Stage_Finished :
            begin
              // Registar na grelha de produção realizada
              row := GridProducaoRealizada.RowCount;
              GridProducaoRealizada.RowCount := row + 1;
              GridProducaoRealizada.Cells[0, row] := 'Expedicao';
              GridProducaoRealizada.Cells[1, row] := IntToStr(part_type);
              GridProducaoRealizada.Cells[2, row] := 'Concluido';
              GridProducaoRealizada.Cells[3, row] := TimeToStr(Now);

              current_operation := Stage_Finished;
            end;
      end;
  end;
end;


procedure TFormDispatcher.Execute_Production_Order(var task: TTask; shopfloor: TResources);


var
  r            : integer;
  raw_material : integer;
  free_pos     : integer;
  row : integer;
begin

  // Determina a matéria-prima necessária com base no tipo de peça final
  case task.part_type of
    Part_Base_Blue,  Part_Lid_Blue  : raw_material := Part_Raw_Blue;
    Part_Base_Green, Part_Lid_Green : raw_material := Part_Raw_Green;
    Part_Base_Grey,  Part_Lid_Grey  : raw_material := Part_Raw_Grey;
  else
    raw_material := 0;
  end;

  with task do
  begin
    case current_operation of

      // Inicia a tarefa
      Stage_To_Be_Started:
      begin
        current_operation := Stage_GetPart;
      end;

      // Procura a matéria-prima no armazém
      Stage_GetPart:
      begin
        if shopfloor.AR_free then
        begin
          Part_Position_AR := GET_AR_Position(raw_material, WAREHOUSE_Parts);
          Memo1.Append('Materia-prima encontrada na posicao: ' + IntToStr(Part_Position_AR));

          if Part_Position_AR > 0 then
            current_operation := Stage_Unload
          else
            current_operation := Stage_GetPart;
        end;
      end;

      // Retira a matéria-prima do armazém
      Stage_Unload:
      begin
        Memo1.Append('AR a descarregar posicao: ' + IntToStr(Part_Position_AR));
        r := M_Unload(Part_Position_AR);

        if r = 1 then
          current_operation := Stage_To_AR_Out;
      end;

      // Aguarda a peça no tapete de saída e envia para a célula
      Stage_To_AR_Out:
      begin
        if shopfloor.AR_Out_Part = raw_material then
        begin
          Memo1.Append('A enviar para celula: ' + IntToStr(Part_Destination));
          r := M_Do_Production(Part_Destination);

          if r = 1 then
            current_operation := Stage_Clear_Pos_AR;
        end;
      end;

      // Limpa a posição antiga e aguarda o produto final; armazena-o
      Stage_Clear_Pos_AR:
      begin
        SET_AR_Position(Part_Position_AR, 0, WAREHOUSE_Parts);

        if shopfloor.AR_In_Part = part_type then
        begin
          free_pos := GET_AR_Position(0, WAREHOUSE_Parts);

          if free_pos > 0 then
          begin
            Memo1.Append('A armazenar produto final na posicao: ' + IntToStr(free_pos));
            r := M_Load(free_pos);

            if r = 1 then
            begin
              SET_AR_Position(free_pos, part_type, WAREHOUSE_Parts);
              current_operation := Stage_Finished;
            end;
          end;
        end;
      end;

      // Tarefa concluída
      Stage_Finished:
        begin
          // Registar na grelha de produção realizada
          row := GridProducaoRealizada.RowCount;
          GridProducaoRealizada.RowCount := row + 1;
          GridProducaoRealizada.Cells[0, row] := 'Producao';
          GridProducaoRealizada.Cells[1, row] := IntToStr(part_type);
          GridProducaoRealizada.Cells[2, row] := 'Concluido';
          GridProducaoRealizada.Cells[3, row] := TimeToStr(Now);

          current_operation := Stage_Finished;
        end;

    end;
  end;
end;


procedure TFormDispatcher.Execute_Inbound_Order(var task: TTask; shopfloor: TResources);
var
  r        : integer;
  row : integer;

begin
  with task do
  begin
    case current_operation of

      // Inicia a tarefa
      Stage_To_Be_Started:
      begin
        current_operation := Stage_GetPart;
      end;

      // Verifica se o Inbound está livre para receber a peça
      Stage_GetPart:
      begin
        if shopfloor.Inbound_free then
        begin
          Memo1.Append('Inbound livre, a enviar peça: ' + IntToStr(part_type));
          r := M_Do_Inbound(part_type);

          if r = 1 then
            current_operation := Stage_Load
          else
            current_operation := Stage_GetPart;
        end;
      end;

      // Espera que a peça chegue à entrada do armazém
      Stage_Load:
      begin
        if shopfloor.AR_In_Part = part_type then
        begin
          Memo1.Append('Peça chegou a entrada do armazem: ' + IntToStr(part_type));
          current_operation := Stage_To_AR_In;
        end;
      end;

      // Procura posição livre e armazena a peça
      Stage_To_AR_In:
          begin
            if shopfloor.AR_free then
            begin
              Part_Position_AR := GET_AR_Position(0, WAREHOUSE_Parts);

              if Part_Position_AR > 0 then
              begin
                Memo1.Append('A armazenar na posição: ' + IntToStr(Part_Position_AR));
                r := M_Load(Part_Position_AR);

                if r = 1 then
                  current_operation := Stage_Clear_Pos_AR;
              end;
            end;
          end;

      // Atualiza o mapa interno do armazém
      Stage_Clear_Pos_AR:
          begin
            SET_AR_Position(Part_Position_AR, part_type, WAREHOUSE_Parts);
            Memo1.Append('Armazem atualizado: posição ' + IntToStr(Part_Position_AR) +
                         ' com peça ' + IntToStr(part_type));
            current_operation := Stage_Finished;
          end;

      // Tarefa concluída
      Stage_Finished:
          begin
            // Registar na grelha de produção realizada
            row := GridProducaoRealizada.RowCount;
            GridProducaoRealizada.RowCount := row + 1;
            GridProducaoRealizada.Cells[0, row] := 'Aprovisionamento';
            GridProducaoRealizada.Cells[1, row] := IntToStr(part_type);
            GridProducaoRealizada.Cells[2, row] := 'Concluido';
            GridProducaoRealizada.Cells[3, row] := TimeToStr(Now);

            current_operation := Stage_Finished;
          end;

    end;
  end;
end;


end.
