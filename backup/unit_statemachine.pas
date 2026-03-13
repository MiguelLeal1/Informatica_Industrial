unit unit_statemachine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Type

  //***************************************
  // Controlling the Production:

  TResources = record
   AR_free      : Boolean;    // true (free) or false (busy)
   AR_In_Part   : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   AR_Out_Part  : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_1_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)
   Robot_2_Part : integer;    // Com uma peça do tipo P={0..9} (0=sem peça)

   Inbound_free : Boolean;    // true (free) or false (busy)
  end;


  // Enumerated: defines the type of the TTask
  TTask_Type  = (Type_Expedition = 1, Type_Delivery, Type_Production, Type_Trash);

  // Enumerated: defines all stages of TTasks
  TStage      = (EXP_Start = 1, EXP_GetPart, EXP_Unload, EXP_TO_AR_OUT, EXP_Clear_Pos_AR, EXP_Finished);   //TbC



  { Data structure for holding one Task (OE, OD, OP) }
  TTask = record
   task_type           : TTask_Type; // type
   current_operation   : TStage;     // the stage that is currently active
   next_operation      : TStage;     // the next stage that will be started as soon as the resource is available
  end;

  //for dynamic arrays
  TArray_Task = array of TTask;      // NOTE: this "type" will originate a varible to hold the output from the scheduling ("sequenciador").


implementation


procedure Dispatcher(var tasks:TArray_Task; var idx : integer; shopfloor: TResources );
var
    Delivery_isFREE : BOOLEAN = false;
    Delivery_hasPart : BOOLEAN = false;
    WI_hasPart : BOOLEAN = false;
    AR_isFREE  : BOOLEAN = false;
begin
  with tasks[idx] do
  begin

  case current_stage of

    { Waiting }
    Stage_Waiting :
    begin
      // Delivery_isFREE :=   get status Delivery

      if (Delivery_isFREE) then
      begin
        NULL;
       // send RECEIVE(...)        { using information in tasks[idx] }
      end;

      // Delivery_hasPart :=   get part Delivery    {we need to confirm that PLC received command: check SEQ_ID}
      if (Delivery_hasPart) then
      begin
         next_stage:= Stage_1_Started;
      end
      else
          next_stage:= Stage_Waiting;

    end;


    { Part is on delivery }
    Stage_1_Started:
    begin
      // Delivery_hasPart :=   get part Delivery   {check SEQ_ID}

      if (Delivery_hasPart) then
      begin
          next_stage:= Stage_1_Concluded;
      end
      else
        next_stage:= Stage_1_Started;
    end;


    { Part reached WI and Part will be transported by AR as soon as AR is free      }
    Stage_1_Concluded:
    begin
      // WI_hasPart :=   get part WI    {check SEQ_ID}   if SEQ_ID of the part that is on WI conveyor then the part reached the AR

      if (WI_hasPart) then
      begin
          //send cmd LOAD(...)
      end;

      // AR_isFREE :=   get status AR

      if (NOT AR_isFREE) then
      begin
         next_stage:= Stage_2_Started;
      end
      else
         next_stage:= Stage_1_Concluded;
    end;


    { Part is being moved by AR }
    Stage_2_Started:
    begin
      // AR_isFREE :=   get status AR

      if (NOT AR_isFREE) then
      begin
         next_stage:= Stage_2_Started;
      end
      else
      begin
         next_stage:= Stage_2_Concluded;   { Part was saved by AR }
         inc (idx );
      end;
    end;
    end;

  end;
end;

end.

