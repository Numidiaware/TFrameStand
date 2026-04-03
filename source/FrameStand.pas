unit FrameStand;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections, System.Threading, System.Rtti,
  System.Types,
  FMX.Types, FMX.Controls, FMX.Forms,
  SubjectStand;

type
  TFrameClass = class of TFrame;
  TFrameStand = class; // fwd

  FrameStandAttribute = class(ContextAttribute);
  FrameInfoAttribute = class(ContextAttribute);

  // --- Layout Parameters Record ---
  TFrameParams = record
    Align: TAlignLayout;
    Margins: TRectF;
    Padding: TRectF;
    class function Default: TFrameParams; static;
    class function Create(AAlign: TAlignLayout; const AMargins, APadding: TRectF): TFrameParams; overload; static;
    class function Create(AAlign: TAlignLayout; AMarginAll: Single = 0; APaddingAll: Single = 0): TFrameParams; overload; static;
    procedure ApplyTo(AControl: TControl);
  end;

  TFrameInfo<T: TFrame> = class(TSubjectInfo)
  private
    FFrame: T;
    FFrameIsOwned: Boolean;
    function GetFrameStand: TFrameStand;
  protected
    function GetSubject: TSubject; override;
    procedure SetSubject(const Value: TSubject); override;
    function GetSubjectIsOwned: Boolean; override;
    procedure SetSubjectIsOwned(const Value: Boolean); override;
    procedure InjectContextAttribute(const AAttribute: ContextAttribute;
      const AField: TRttiField; const AFieldClassType: TClass); override;
  public
    constructor Create(const AFrameStand: TFrameStand; const AFrame: T;
      const AParent: TFmxObject; const AStandStyleName: string); reintroduce; virtual;

    function Show(const ABackgroundTask: TProc<TFrameInfo<T>> = nil;
      const AOnTaskComplete: TProc<TFrameInfo<T>> = nil;
      const AOnTaskCompleteSynchronized: Boolean = True): ITask; overload; deprecated;

    procedure Show(); overload;

    property FrameIsOwned: Boolean read FFrameIsOwned write FFrameIsOwned;
    property Frame: T read FFrame;
    property FrameStand: TFrameStand read GetFrameStand;
  end;

  TOnGetFrameClassEvent = procedure (const ASender: TFrameStand; var AParent: TFmxObject;
    var AStandStyleName: string; var AFrameClass: TFrameClass) of object;

  TFrameStand = class(TSubjectStand)
  private
    FOnGetFrameClass: TOnGetFrameClassEvent;
    FVisibleFrames : TList<TFrame>;
    FFrameClasses: TList<TFrameClass>;
    FFrameParams: TDictionary<TFrameClass, TFrameParams>;

    // Property Getters/Setters
    function GetFrameIndex: Integer;
    procedure SetFrameIndex(const Value: Integer);
    function GetActiveFrame: TFrame;
    procedure SetActiveFrame(const Value: TFrame);
  protected
    FFrameInfos: TObjectDictionary<TFrame, TFrameInfo<TFrame>>;
    function GetCount: Integer; override;
    function GetFrameClass<T: TFrame>(var AParent: TFmxObject; var AStandStyleName: string): TFrameClass; overload;
    function GetFrameClass(const AClassName: string; var AParent: TFmxObject; var AStandStyleName: string): TFrameClass; overload;
    procedure DoAfterHide(const ASender: TSubjectStand; const ASubjectInfo: TSubjectInfo); override;
    procedure DoBeforeShow(const ASender: TSubjectStand; const ASubjectInfo: TSubjectInfo); override;
    procedure DoClose(const ASubject: TFmxObject); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function LastShownFrame: TFrame;
    procedure Remove(ASubject: TSubject); override;
    procedure CloseAll(const ARestrictTo: TArray<TClass>); overload; override;
    procedure CloseAllExcept(const AExceptions: TArray<TClass>); overload; override;
    procedure HideAndCloseAll(const ARestrictTo: TArray<TClass>); overload; override;
    procedure HideAndCloseAllExcept(const AExceptions: TArray<TClass>); overload; override;

    function FrameInfo(const AFrame: TFrame): TFrameInfo<TFrame>; overload;
    function FrameInfo(const AFrameClass: TFrameClass): TFrameInfo<TFrame>; overload;
    function FrameInfo<T: TFrame>: TFrameInfo<T>; overload;
    function GetFrameInfo<T: TFrame>(const ANewIfNotFound: Boolean = True;
      const AParent: TFmxObject = nil; const AStandStyleName: string = ''): TFrameInfo<T>;

    function Use<T: TFrame>(const AFrame: T; const AParent: TFmxObject = nil;
      const AStandStyleName: string = ''): TFrameInfo<T>; overload;
    function Use(const AFrame: TFrame; const AParent: TFmxObject = nil;
      const AStandStyleName: string = ''): TFrameInfo<TFrame>; overload;

    function New<T: TFrame>(const AParent: TFmxObject = nil;
      const AStandStyleName: string = ''): TFrameInfo<T>; overload;
    function New(const AFrameClassName: string; const AParent: TFmxObject = nil;
      const AStandStyleName: string = ''): TFrameInfo<TFrame>; overload;

    function NewAndShow<T: TFrame>(const AParent: TFmxObject = nil;
      const AStandStyleName: string = ''; const AConfigProc: TProc<T> = nil;
      const AConfigFIProc: TProc<TFrameInfo<T>> = nil): TFrameInfo<T>;

    // --- FRAME MANAGEMENT ---
    procedure RegisterFrame(AFrameClass: TFrameClass); overload;
    procedure RegisterFrame(AFrameClass: TFrameClass; const AParams: TFrameParams); overload;

    // --> NEW ARRAY PARAMETER OVERLOADS <--
    procedure RegisterFrame(const AFrameClasses: array of TFrameClass); overload;
    procedure RegisterFrame(const AFrameClasses: array of TFrameClass; const AParams: TFrameParams); overload;

    procedure SwitchFrame(AFrameClass: TFrameClass); overload;
    procedure SwitchFrame(AFrameClass: TFrameClass; const AParams: TFrameParams); overload;
    procedure SwitchFrame(AFrame: TFrame); overload;
    procedure SwitchFrame(AIndex: Integer); overload;
    procedure SwitchFrame(const AClassName: string); overload;

    property FrameInfos: TObjectDictionary<TFrame, TFrameInfo<TFrame>> read FFrameInfos;
    property VisibleFrames: TList<TFrame> read FVisibleFrames;
    property FrameClasses: TList<TFrameClass> read FFrameClasses;

    property FrameIndex: Integer read GetFrameIndex write SetFrameIndex;
    property ActiveFrame: TFrame read GetActiveFrame write SetActiveFrame;
  published
    property OnGetSubjectClass: TOnGetFrameClassEvent read FOnGetFrameClass write FOnGetFrameClass;
  end;

implementation

{ TFrameParams }

class function TFrameParams.Default: TFrameParams;
begin
  Result.Align := TAlignLayout.Client;
  Result.Margins := TRectF.Empty;
  Result.Padding := TRectF.Empty;
end;

class function TFrameParams.Create(AAlign: TAlignLayout; const AMargins, APadding: TRectF): TFrameParams;
begin
  Result.Align := AAlign;
  Result.Margins := AMargins;
  Result.Padding := APadding;
end;

class function TFrameParams.Create(AAlign: TAlignLayout; AMarginAll: Single = 0; APaddingAll: Single = 0): TFrameParams;
begin
  Result.Align := AAlign;
  Result.Margins := TRectF.Create(AMarginAll, AMarginAll, AMarginAll, AMarginAll);
  Result.Padding := TRectF.Create(APaddingAll, APaddingAll, APaddingAll, APaddingAll);
end;

procedure TFrameParams.ApplyTo(AControl: TControl);
begin
  if Assigned(AControl) then
  begin
    AControl.Align := Align;
    AControl.Margins.Left := Margins.Left;
    AControl.Margins.Top := Margins.Top;
    AControl.Margins.Right := Margins.Right;
    AControl.Margins.Bottom := Margins.Bottom;

    AControl.Padding.Left := Padding.Left;
    AControl.Padding.Top := Padding.Top;
    AControl.Padding.Right := Padding.Right;
    AControl.Padding.Bottom := Padding.Bottom;
  end;
end;

{ TFrameStand }

constructor TFrameStand.Create(AOwner: TComponent);
begin
  inherited;
  FFrameInfos := TObjectDictionary<TFrame, TFrameInfo<TFrame>>.Create();
  FVisibleFrames := TList<TFrame>.Create;
  FFrameClasses := TList<TFrameClass>.Create;
  FFrameParams := TDictionary<TFrameClass, TFrameParams>.Create;
end;

destructor TFrameStand.Destroy;
var
  LKey: TFrame;
begin
  for LKey in FFrameInfos.Keys.ToArray do
    Remove(LKey);
  FreeAndNil(FFrameInfos);
  FreeAndNil(FVisibleFrames);
  FreeAndNil(FFrameClasses);
  FreeAndNil(FFrameParams);

  inherited;
end;

// ==========================================
// --- PROPERTIES IMPLEMENTATION ---
// ==========================================

function TFrameStand.GetActiveFrame: TFrame;
begin
  Result := LastShownFrame;
end;

procedure TFrameStand.SetActiveFrame(const Value: TFrame);
begin
  if GetActiveFrame <> Value then
  begin
    if Assigned(Value) then
      SwitchFrame(Value)
    else
    begin
      for var LFrame in FVisibleFrames.ToArray do
        FrameInfo(LFrame).Hide;
    end;
  end;
end;

function TFrameStand.GetFrameIndex: Integer;
var
  LActive: TFrame;
begin
  LActive := ActiveFrame;
  if Assigned(LActive) then
    Result := FFrameClasses.IndexOf(TFrameClass(LActive.ClassType))
  else
    Result := -1;
end;

procedure TFrameStand.SetFrameIndex(const Value: Integer);
begin
  if Value = -1 then
    ActiveFrame := nil // Hide all
  else if (Value >= 0) and (Value < FFrameClasses.Count) then
  begin
    if GetFrameIndex <> Value then
      SwitchFrame(Value);
  end
  else
    raise Exception.CreateFmt('TFrameStand.FrameIndex: Index out of bounds (%d)', [Value]);
end;

// ==========================================
// --- STANDARD METHODS ---
// ==========================================

procedure TFrameStand.CloseAll(const ARestrictTo: TArray<TClass>);
var
  LFrameInfo: TFrameInfo<TFrame>;
  LFrameInfos: TArray<TFrameInfo<TFrame>>;
  LConsiderRestrictions: Boolean;
begin
  LFrameInfos := FFrameInfos.Values.ToArray;
  LConsiderRestrictions := Length(ARestrictTo) > 0;
  for LFrameInfo in LFrameInfos do
  begin
    if (not LConsiderRestrictions) or ClassInArray(LFrameInfo.Frame, ARestrictTo) then
      LFrameInfo.Close;
  end;
end;

procedure TFrameStand.CloseAllExcept(const AExceptions: TArray<TClass>);
var
  LFrameInfo: TFrameInfo<TFrame>;
  LFrameInfos: TArray<TFrameInfo<TFrame>>;
  LConsiderExceptions: Boolean;
begin
  LFrameInfos := FFrameInfos.Values.ToArray;
  LConsiderExceptions := Length(AExceptions) > 0;
  for LFrameInfo in LFrameInfos do
  begin
    if (not LConsiderExceptions) or not ClassInArray(LFrameInfo.Frame, AExceptions) then
      LFrameInfo.Close;
  end;
end;

procedure TFrameStand.DoAfterHide(const ASender: TSubjectStand; const ASubjectInfo: TSubjectInfo);
begin
  inherited;
  FVisibleFrames.Remove(ASubjectInfo.Subject as TFrame);
end;

procedure TFrameStand.DoBeforeShow(const ASender: TSubjectStand; const ASubjectInfo: TSubjectInfo);
begin
  inherited;
   FVisibleFrames.Add(ASubjectInfo.Subject as TFrame);
end;

procedure TFrameStand.DoClose(const ASubject: TFmxObject);
begin
  FVisibleFrames.Remove(ASubject as TFrame);
  inherited;
end;

function TFrameStand.FrameInfo(const AFrameClass: TFrameClass): TFrameInfo<TFrame>;
var
  LPair: TPair<TFrame, TFrameInfo<TFrame>>;
begin
  Result := nil;
  for LPair in FFrameInfos do
  begin
    if LPair.Key is AFrameClass then
    begin
      Result := LPair.Value;
      Break;
    end;
  end;
end;

function TFrameStand.FrameInfo<T>: TFrameInfo<T>;
begin
  Result := TFrameInfo<T>(FrameInfo(TFrameClass(T)));
end;

function TFrameStand.FrameInfo(const AFrame: TFrame): TFrameInfo<TFrame>;
begin
  Result := nil;
  FFrameInfos.TryGetValue(AFrame, Result);
end;

function TFrameStand.GetCount: Integer;
begin
  Result := FFrameInfos.Count;
end;

function TFrameStand.GetFrameClass(const AClassName: string; var AParent: TFmxObject; var AStandStyleName: string): TFrameClass;
begin
  var LContext := TRttiContext.Create;
  var LType := LContext.FindType(AClassName);

  if not Assigned(LType) then
  begin
    var LTypes := LContext.GetTypes;
    for var LSearchType in LTypes do
    begin
      if SameText(LSearchType.Name, AClassName) then
      begin
        LType := LSearchType;
        Break;
      end;
    end;
  end;

  if not Assigned(LType) then
    raise Exception.CreateFmt('Type not found: %s', [AClassName]);
  if not (LType is TRttiInstanceType) then
    raise Exception.CreateFmt('Type %s is not an instance type', [AClassName]);

  var LInstanceType := LType as TRttiInstanceType;
  if not (LInstanceType.MetaclassType.InheritsFrom(TFrame)) then
    raise Exception.CreateFmt('Type %s is not a TFrame descendant', [AClassName]);

  Result := TFrameClass(LInstanceType.MetaclassType);
  DoResponsiveLookup(TSubjectClass(Result), AStandStyleName, AParent);
  if Assigned(FOnGetFrameClass) then
    FOnGetFrameClass(Self, AParent, AStandStyleName, Result);
end;

function TFrameStand.GetFrameClass<T>(var AParent: TFmxObject; var AStandStyleName: string): TFrameClass;
begin
  Result := TFrameClass(T);
  DoResponsiveLookup(TSubjectClass(Result), AStandStyleName, AParent);
  if Assigned(FOnGetFrameClass) then
    FOnGetFrameClass(Self, AParent, AStandStyleName, Result);
end;

function TFrameStand.GetFrameInfo<T>(const ANewIfNotFound: Boolean = True;
  const AParent: TFmxObject = nil; const AStandStyleName: string = ''): TFrameInfo<T>;
begin
  Result := FrameInfo<T>;
  if ANewIfNotFound and not Assigned(Result) then
    Result := New<T>(AParent, AStandStyleName);
end;

procedure TFrameStand.HideAndCloseAll(const ARestrictTo: TArray<TClass>);
var
  LFrameInfo: TFrameInfo<TFrame>;
  LFrameInfos: TArray<TFrameInfo<TFrame>>;
  LConsiderRestrictions: Boolean;
begin
  LFrameInfos := FFrameInfos.Values.ToArray;
  LConsiderRestrictions := Length(ARestrictTo) > 0;
  for LFrameInfo in LFrameInfos do
  begin
    if (not LConsiderRestrictions) or ClassInArray(LFrameInfo.Frame, ARestrictTo) then
      LFrameInfo.HideAndClose;
  end;
end;

procedure TFrameStand.HideAndCloseAllExcept(const AExceptions: TArray<TClass>);
var
  LFrameInfo: TFrameInfo<TFrame>;
  LFrameInfos: TArray<TFrameInfo<TFrame>>;
  LConsiderExceptions: Boolean;
begin
  LFrameInfos := FFrameInfos.Values.ToArray;
  LConsiderExceptions := Length(AExceptions) > 0;
  for LFrameInfo in LFrameInfos do
  begin
    if (not LConsiderExceptions) or not ClassInArray(LFrameInfo.Frame, AExceptions) then
      LFrameInfo.HideAndClose;
  end;
end;

function TFrameStand.LastShownFrame: TFrame;
begin
  Result := nil;
  if FVisibleFrames.Count > 0 then
    Result := FVisibleFrames.Last;
end;

function TFrameStand.New(const AFrameClassName: string;
  const AParent: TFmxObject; const AStandStyleName: string): TFrameInfo<TFrame>;
var
  LFrame: TFrame;
  LParent: TFmxObject;
  LStandName: string;
begin
  LParent := AParent;
  if not Assigned(LParent) then
    LParent := GetDefaultParent;
  LStandName := AStandStyleName;
  LFrame := GetFrameClass(AFrameClassName, LParent, LStandName).Create(nil);
  try
    LFrame.Name := '';
    Result := Use(LFrame, LParent, LStandName);
    Result.FrameIsOwned := True;
  except
    LFrame.Free;
    raise;
  end;
end;

function TFrameStand.New<T>(const AParent: TFmxObject; const AStandStyleName: string): TFrameInfo<T>;
var
  LFrame: T;
  LParent: TFmxObject;
  LStandName: string;
begin
  LParent := AParent;
  if not Assigned(LParent) then
    LParent := GetDefaultParent;
  LStandName := AStandStyleName;
  LFrame := T(GetFrameClass<T>(LParent, LStandName).Create(nil));
  try
    LFrame.Name := '';
    Result := Use<T>(LFrame, LParent, LStandName);
    Result.FrameIsOwned := True;
  except
    LFrame.Free;
    raise;
  end;
end;

function TFrameStand.NewAndShow<T>(const AParent: TFmxObject;
  const AStandStyleName: string; const AConfigProc: TProc<T>;
  const AConfigFIProc: TProc<TFrameInfo<T>>): TFrameInfo<T>;
begin
  Result := New<T>(AParent, AStandStyleName);
  if Assigned(AConfigProc) then
    AConfigProc(Result.Frame);
  if Assigned(AConfigFIProc) then
    AConfigFIProc(Result);
  Result.Show();
end;

procedure TFrameStand.Remove(ASubject: TSubject);
var
  LInfo: TFrameInfo<TFrame>;
  LFrame: TFrame;
begin
  inherited;
  LFrame := ASubject as TFrame;
  if Assigned(LFrame) and FFrameInfos.TryGetValue(LFrame, LInfo) then
  begin
    FFrameInfos.Remove(LFrame);
    {$IFDEF AUTOREFCOUNT}
      LInfo.DisposeOf;
      LInfo := nil;
    {$ELSE}
      LInfo.Free;
    {$ENDIF}
  end;
end;

// ==========================================
// --- FRAME MANAGEMENT IMPLEMENTATION ---
// ==========================================

procedure TFrameStand.RegisterFrame(AFrameClass: TFrameClass);
begin
  RegisterFrame(AFrameClass, TFrameParams.Default);
end;

procedure TFrameStand.RegisterFrame(AFrameClass: TFrameClass; const AParams: TFrameParams);
begin
  if not Assigned(AFrameClass) then Exit;

  if not FFrameClasses.Contains(AFrameClass) then
    FFrameClasses.Add(AFrameClass);

  // Store or update layout parameters
  FFrameParams.AddOrSetValue(AFrameClass, AParams);
end;

// --> NEW ARRAY IMPLEMENTATIONS <--

procedure TFrameStand.RegisterFrame(const AFrameClasses: array of TFrameClass);
var
  LFrameClass: TFrameClass;
begin
  for LFrameClass in AFrameClasses do
    RegisterFrame(LFrameClass);
end;

procedure TFrameStand.RegisterFrame(const AFrameClasses: array of TFrameClass; const AParams: TFrameParams);
var
  LFrameClass: TFrameClass;
begin
  for LFrameClass in AFrameClasses do
    RegisterFrame(LFrameClass, AParams);
end;

// ---------------------------------

procedure TFrameStand.SwitchFrame(AFrameClass: TFrameClass);
var
  LParams: TFrameParams;
begin
  // Fallback to default if no custom params were registered
  if not FFrameParams.TryGetValue(AFrameClass, LParams) then
    LParams := TFrameParams.Default;

  SwitchFrame(AFrameClass, LParams);
end;

procedure TFrameStand.SwitchFrame(AFrameClass: TFrameClass; const AParams: TFrameParams);
var
  LFrame: TFrame;
  LTargetInfo: TFrameInfo<TFrame>;
begin
  if not Assigned(AFrameClass) then Exit;

  LTargetInfo := FrameInfo(AFrameClass);
  if not Assigned(LTargetInfo) then
    LTargetInfo := New(AFrameClass.ClassName); // Lazy Load

  // Apply layout parameters (Align, Margin, Padding) to the physical TFrame
  AParams.ApplyTo(LTargetInfo.Frame);

  for LFrame in FVisibleFrames.ToArray do
  begin
    if LFrame <> LTargetInfo.Frame then
      FrameInfo(LFrame).Hide;
  end;

  LTargetInfo.Show();
end;

procedure TFrameStand.SwitchFrame(AFrame: TFrame);
var
  LFrame: TFrame;
  LTargetInfo: TFrameInfo<TFrame>;
  LParams: TFrameParams;
begin
  if not Assigned(AFrame) then Exit;

  LTargetInfo := FrameInfo(AFrame);
  if not Assigned(LTargetInfo) then
    raise Exception.Create('TFrameStand.SwitchFrame: Frame instance is not managed by this FrameStand.');

  // Check if there are default parameters assigned for its class type
  if not FFrameParams.TryGetValue(TFrameClass(AFrame.ClassType), LParams) then
    LParams := TFrameParams.Default;

  LParams.ApplyTo(AFrame);

  // Hide non-active frames
  for LFrame in FVisibleFrames.ToArray do
  begin
    if LFrame <> AFrame then
      FrameInfo(LFrame).Hide;
  end;

  LTargetInfo.Show();
end;

procedure TFrameStand.SwitchFrame(AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < FFrameClasses.Count) then
    SwitchFrame(FFrameClasses[AIndex])
  else
    raise Exception.CreateFmt('TFrameStand.SwitchFrame: Index out of bounds (%d)', [AIndex]);
end;

procedure TFrameStand.SwitchFrame(const AClassName: string);
var
  LFrameClass, LTargetClass: TFrameClass;
  LDummyParent: TFmxObject;
  LDummyStand: string;
begin
  LTargetClass := nil;

  for LFrameClass in FFrameClasses do
  begin
    if SameText(LFrameClass.ClassName, AClassName) then
    begin
      LTargetClass := LFrameClass;
      Break;
    end;
  end;

  if not Assigned(LTargetClass) then
  begin
    LDummyParent := nil;
    LDummyStand := '';
    LTargetClass := GetFrameClass(AClassName, LDummyParent, LDummyStand);
  end;

  if Assigned(LTargetClass) then
    SwitchFrame(LTargetClass)
  else
    raise Exception.CreateFmt('TFrameStand.SwitchFrame: Cannot find frame class "%s"', [AClassName]);
end;

function TFrameStand.Use(const AFrame: TFrame; const AParent: TFmxObject;
  const AStandStyleName: string): TFrameInfo<TFrame>;
begin
  Result := Use<TFrame>(AFrame, AParent, AStandStyleName);
end;

function TFrameStand.Use<T>(const AFrame: T; const AParent: TFmxObject;
  const AStandStyleName: string): TFrameInfo<T>;
var
  LStandStyleName: string;
  LParent: TFmxObject;
begin
  LStandStyleName := GetStandStyleName(AStandStyleName);
  LParent := AParent;
  if not Assigned(LParent) then
    LParent := GetDefaultParent;

  Result := TFrameInfo<T>.Create(Self, AFrame, LParent, LStandStyleName);
  try
    Result.InjectContext;
    FFrameInfos.Add(Result.Frame, TFrameInfo<TFrame>(Result));
  except
    Result.Free;
    raise;
  end;
end;

{ TFrameInfo<T> }

constructor TFrameInfo<T>.Create(const AFrameStand: TFrameStand;
  const AFrame: T; const AParent: TFmxObject; const AStandStyleName: string);
begin
  Assert(Assigned(AFrameStand));
  Assert(Assigned(AFrame));

  FFrame := AFrame;
  FFrameIsOwned := False;

  inherited Create(AFrameStand, AFrame, AParent, AStandStyleName);
end;

function TFrameInfo<T>.GetFrameStand: TFrameStand;
begin
  Result := SubjectStand as TFrameStand;
end;

function TFrameInfo<T>.GetSubject: TSubject;
begin
  Result := FFrame;
end;

function TFrameInfo<T>.GetSubjectIsOwned: Boolean;
begin
  Result := FFrameIsOwned;
end;

procedure TFrameInfo<T>.InjectContextAttribute(
  const AAttribute: ContextAttribute; const AField: TRttiField;
  const AFieldClassType: TClass);
begin
  inherited;
  if (AAttribute is FrameStandAttribute) and (AFieldClassType.InheritsFrom(TFrameStand)) then
      AField.SetValue(TObject(Frame), FrameStand)
  else if (AAttribute is FrameInfoAttribute) then
    AField.SetValue(TObject(Frame), Self);
end;

procedure TFrameInfo<T>.SetSubject(const Value: TSubject);
begin
  inherited;
  FFrame := T(Value);
end;

procedure TFrameInfo<T>.SetSubjectIsOwned(const Value: Boolean);
begin
  inherited;
  FFrameIsOwned := Value;
end;

procedure TFrameInfo<T>.Show;
begin
  SubjectShow();
end;

function TFrameInfo<T>.Show(const ABackgroundTask,
  AOnTaskComplete: TProc<TFrameInfo<T>>;
  const AOnTaskCompleteSynchronized: Boolean): ITask;
begin
{$WARN SYMBOL_DEPRECATED OFF}
  Result := SubjectShow(
    TProc<TSubjectInfo>(ABackgroundTask)
  , TProc<TSubjectInfo>(AOnTaskComplete)
  , AOnTaskCompleteSynchronized
  );
{$WARN SYMBOL_DEPRECATED ON}
end;

end.
