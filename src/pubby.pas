{ Pubby - a flexible pub/sub implementation

  Copyright (c) 2018 mr-highball

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
}

unit pubby;

{$mode delphi}{$H+}

interface

uses
  Classes, SysUtils;

type
  TIntfList =
    {$IFDEF FPC}
    TInterfaceList
    {$ELSE}
    //todo - look at embarcadero wiki to find proper class,
    //may be the same definition as fgl
    TInterfaceList
    {$ENDIF};


  { ISubscriberBase }
  (*
    intermediary subscriber to bypass no forward declaration of generics
  *)
  ISubscriberBase<T> = interface
    ['{295F4B43-35DB-4A36-9651-61984D61A7FE}']
    //methods
    function Notify(Const AMessage:T;Const ASender:IInterface;
      Out Error:String):Boolean;
  end;

  (*
    event triggered by a subscriber if calling Notify results in failure
  *)
  TSubNotifyErrorEvent<T> = procedure(Const ASender:ISubscriberBase;
    Const AMessage:T;Const AError:String) of object;

  (*
    event occurring directly before Notify logic is called. If AbortNotfiy
    is set to True, then Notify logic will not run and report success
  *)
  TSubBeforeNotifyEvent<T> = procedure(Const ASender:ISubscriberBase;
    Const AMessage:T;Out AbortNotify:Boolean) of object;

  (*
    event occurring after notify success
  *)
  TSubAfterNotifyEvent<T> = procedure(Const ASender:ISubscriberBase;
    Const AMessage:T) of object;

  { ISubscriber }
  (*
    subscriber to a publisher
  *)
  ISubscriber<T> = interface(ISubscriberBase<T>)
    ['{5680F6E0-F6A4-42D3-A259-DDC7E4C9B2EE}']
    //property methods
    function GetErrorEvent: TSubNotifyErrorEvent<T>;
    procedure SetErrorEvent(Const AValue: TSubNotifyErrorEvent<T>);
    procedure SetAfterEvent(Const AValue: TSubAfterNotifyEvent<T>);
    procedure SetBeforeEvent(Const AValue: TSubBeforeNotifyEvent<T>);
    function GetAfterEvent: TSubAfterNotifyEvent<T>;
    function GetBeforeEvent: TSubBeforeNotifyEvent<T>;
    //properties
    property OnError : TSubNotifyErrorEvent<T> read GetErrorEvent
      write SetErrorEvent;
    property OnBeforeNotify : TSubBeforeNotifyEvent<T> read GetBeforeEvent
      write SetBeforeEvent;
    property OnAfterNotify : TSubAfterNotifyEvent<T> read GetAfterEvent
      write SetAfterEvent;
  end;

  { IPublisherBase }
  (*
    intermediary publisher to bypass no forward declaration of generics
  *)
  IPublisherBase<T> = interface
    ['{E2F65A97-6293-4FAD-B264-BDA6C98F1D4B}']
    //methods
    procedure Subscribe(Const ASubscriber:ISubscriber<T>);
    procedure Unsubscribe(Const ASubscriber:ISubscriber<T>);
    procedure Notify(Const AMessage:T);
  end;

  (*
    event triggered by a publisher if calling Notify of a subscriber results
    in failure
  *)
  TPubNotifyErrorEvent<T> = procedure(Const ASender:IPublisherBase;
    Const ASubscriber:ISubscriber;Const AMessage:T;Const AError:String) of object;

  { IPublisher }
  (*
    publisher of some type of message
  *)
  IPublisher<T> = interface(IPublisherBase<T>)
    ['{07CA49CC-4052-40FB-A8D8-547B57EDCB6C}']
    //property methods
    function GetErrorEvent: TPubNotifyErrorEvent<T>;
    procedure SetErrorEvent(Const AValue: TPubNotifyErrorEvent<T>);
    //properties
    property OnError : TPubNotifyErrorEvent<T> read GetErrorEvent
      write SetErrorEvent;
  end;

  { TSubscriberImpl }
  (*
    base class implementing the ISubscriber interface
  *)
  TSubscriberImpl<T> = class(TInterfacedObject,ISubscriber<T>)
  strict private
    FErrorEvent : TSubNotifyErrorEvent<T>;
    FBeforeEvent : TSubBeforeNotifyEvent<T>;
    FAfterEvent : TSubAfterNotifyEvent<T>;
    function GetAfterEvent: TSubAfterNotifyEvent<T>;
    function GetBeforeEvent: TSubBeforeNotifyEvent<T>;
    function GetErrorEvent: TSubNotifyErrorEvent<T>;
    procedure SetAfterEvent(Const AValue: TSubAfterNotifyEvent<T>);
    procedure SetBeforeEvent(Const AValue: TSubBeforeNotifyEvent<T>);
    procedure SetErrorEvent(Const AValue: TSubNotifyErrorEvent<T>);
  strict protected
    procedure DoOnError(Const ASender:ISubscriberBase<T>;
      Const AMessage:T;Const AError:String);
    procedure DoOnBeforeNotify(Const ASender:ISubscriberBase<T>;
      Const AMessage:T;Out AbortNotify:Boolean);
    procedure DoOnAfterNotify(Const ASender:ISubscriberBase<T>;Const AMessage:T);

    //children classes need to override this to perform notify logic
    function DoNotify(Const AMessage:T;Const APublisher:IPublisher<T>;
      Out Error:String):Boolean;virtual;abstract;
  public
    property OnError : TSubNotifyErrorEvent<T> read GetErrorEvent
      write SetErrorEvent;
    property OnBeforeNotify : TSubBeforeNotifyEvent<T> read GetBeforeEvent
      write SetBeforeEvent;
    property OnAfterNotify : TSubAfterNotifyEvent<T> read GetAfterEvent
      write SetAfterEvent;
    function Notify(Const AMessage:T;Const ASender:IInterface;
      Out Error:String):Boolean;
  end;

  { TPublisherImpl }
  (*
    base class implementing the IPublisher interface
  *)
  TPublisherImpl<T> = class(TInterfacedObject,IPublisher<T>)
  strict private
    FErrorEvent : TPubNotifyErrorEvent<T>;
    FList : TIntfList;
    function GetErrorEvent: TPubNotifyErrorEvent;
    procedure SetErrorEvent(Const AValue: TPubNotifyErrorEvent<T>);
  strict protected
    procedure DoOnError(Const ASender:IPublisher<T>;
      Const ASubscriber:ISubscriber<T>;Const AMessage:T;Const AError:String);
  public
    property OnError : TPubNotifyErrorEvent<T> read GetErrorEvent
      write SetErrorEvent;
    procedure Subscribe(Const ASubscriber:ISubscriber<T>);
    procedure Unsubscribe(Const ASubscriber:ISubscriber<T>);
    procedure Notify(Const AMessage:T);
    constructor Create;virtual;
    destructor Destroy; override;
  end;

implementation

{ TSubscriberImpl }

function TSubscriberImpl<T>.GetAfterEvent: TSubAfterNotifyEvent<T>;
begin
  Result:=FAfterEvent;
end;

function TSubscriberImpl<T>.GetBeforeEvent: TSubBeforeNotifyEvent<T>;
begin
  Result:=FBeforeEvent;
end;

function TSubscriberImpl<T>.GetErrorEvent: TSubNotifyErrorEvent<T>;
begin
  Result:=FErrorEvent;
end;

procedure TSubscriberImpl<T>.SetAfterEvent(Const AValue: TSubAfterNotifyEvent<T>);
begin
  FAfterEvent:=AValue;
end;

procedure TSubscriberImpl<T>.SetBeforeEvent(Const AValue: TSubBeforeNotifyEvent<T>);
begin
  FBeforeEvent:=AValue;
end;

procedure TSubscriberImpl<T>.SetErrorEvent(Const AValue: TSubNotifyErrorEvent<T>);
begin
  FErrorEvent:=AValue;
end;

procedure TSubscriberImpl<T>.DoOnError(const ASender: ISubscriberBase<T>;
  const AMessage: T; const AError: String);
begin
  if Assigned(FErrorEvent) then
    FErrorEvent(ASender,AMessage,AError);
end;

procedure TSubscriberImpl<T>.DoOnBeforeNotify(const ASender: ISubscriberBase<T>;
  const AMessage: T; out AbortNotify: Boolean);
begin
  AbortNotify:=False;
  if Assigned(FBeforeEvent) then
    FBeforeEvent(ASender,AMessage,AbortNotify);
end;

procedure TSubscriberImpl<T>.DoOnAfterNotify(const ASender: ISubscriberBase<T>;
  const AMessage: T);
begin
  if Assigned(FAfterEvent) then
    FAfterEvent(ASender,AMessage);
end;

function TSubscriberImpl<T>.Notify(const AMessage: T;
  const ASender: IInterface; out Error: String): Boolean;
var
  LSubscriber:ISubscriber<T>;
  LAbort:Boolean;
begin
  Result:=False;
  try
    LSubscriber:=Self;
    DoOnBeforeNotify(LSubscriber,AMessage,LAbort);
    //see if we need to skip notify logic
    if LAbort then
    begin
      Result:=True;
      //even though we are skipping, still trigger after event since
      //we are reporting success
      DoOnAfterNotify(LSubscriber,AMessage);
      Exit;
    end;
    if not DoNotify(AMessage,ASender as IPublisher<T>,Error) then
      Exit;
    Result:=True;
    DoOnAfterNotify(LSubscriber,AMessage);
  except on E:Exception do
    Error:=E.Message;
  end;
end;

{ TPublisherImpl }

function TPublisherImpl<T>.GetErrorEvent: TPubNotifyErrorEvent;
begin
  Result:=@FErrorEvent;
end;

procedure TPublisherImpl<T>.SetErrorEvent(Const AValue: TPubNotifyErrorEvent<T>);
begin
  FErrorEvent:=AValue;
end;

procedure TPublisherImpl<T>.Subscribe(const ASubscriber: ISubscriber<T>);
var
  I:Integer;
begin
  I:=FList.IndexOf(ASubscriber);
  if I<0 then
    Flist.Add(ASubscriber);
end;

procedure TPublisherImpl<T>.Unsubscribe(const ASubscriber: ISubscriber<T>);
var
  I:Integer;
begin
  I:=FList.IndexOf(ASubscriber);
  if I<0 then
    Exit;
  FList.Delete(I);
end;

procedure TPublisherImpl<T>.Notify(const AMessage: T);
var
  I:Integer;
  LSubscriber:ISubscriber<T>;
  LPublisher:IPublisher<T>;
  LError:String;
begin
  try
    LPublisher:=Self;
    for I:=0 to Pred(FList.Count) do
    begin
      LSubscriber:=FList[I] as ISubscriber<T>;
      if not Assigned(LSubscriber) then
        Continue;
      if not LSubscriber.Notify(AMessage,LPublisher,LError) then
        DoOnError(LPublisher,LSubscriber,AMessage,LError);
    end;
  except on E:Exception do
    DoOnError(LPublisher,LSubscriber,AMessage,LError);
  end;
end;

procedure TPublisherImpl<T>.DoOnError(Const ASender:IPublisher<T>;
  Const ASubscriber:ISubscriber<T>;Const AMessage:T;Const AError:String);
begin
  if Assigned(FErrorEvent) then
    FErrorEvent(ASender,ASubscriber,AMessage,AError);
end;

constructor TPublisherImpl<T>.Create;
begin
  FList:=TIntfList.Create;
end;

destructor TPublisherImpl<T>.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

end.

