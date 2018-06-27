program tests;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, GuiTestRunner, pubby.tests;

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TGuiTestRunner, TestRunner);
  Application.Run;
end.

