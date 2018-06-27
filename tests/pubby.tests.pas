unit pubby.tests;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testutils, testregistry,
  pubby;

type

  IIntSubscriber = ISubscriber<Integer>;
  IIntPublisher = IPublisher<Integer>;
  TIntSubscriberImpl = TSubscriberImpl<Integer>;

  { TTestIntSub }

  TTestIntSub = class(TIntSubscriberImpl)
  private
    FShouldFail: Boolean;
  strict protected
  public
    property ShouldFail : Boolean read FShouldFail write FShouldFail;
  end;

  {$M+}
  TPubbyTest= class(TTestCase)
  protected
    FSubscriber : IIntSubscriber;
    FPublisher : IIntPublisher;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestHookUp;
  end;
implementation

{ TTestIntSub }

procedure TPubbyTest.TestHookUp;
begin
  Fail('Write your own test');
end;

procedure TPubbyTest.SetUp;
begin
  FSubscriber:=TTestIntSub.Create;
  FPublisher:=TPublisherImpl<Integer>.Create;
end;

procedure TPubbyTest.TearDown;
begin
  FSubscriber:=nil;
  FPublisher:=nil;
end;

initialization

  RegisterTest(TPubbyTest);
end.

