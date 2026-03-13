program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, comTestUnit, comUnit, unitdispatcher;

{$R *.res}

begin
     RequireDerivedFormResource:=True;
     Application.Scaled:=True;
     Application.Initialize;
     Application.CreateForm(TFormDispatcher, FormDispatcher);
     Application.CreateForm(TFormComTest, FormComTest);
     Application.CreateForm(TComForm, ComForm);
     Application.Run;
end.

