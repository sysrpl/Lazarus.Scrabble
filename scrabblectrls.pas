(********************************************************)
(*                                                      *)
(*  Get Lazarus Scrabble Example                        *)
(*  https://www.getlazarus.org                          *)
(*  Modified August 2019                                *)
(*                                                      *)
(*  Free open source software released under the LGPL   *)
(*                                                      *)
(********************************************************)

unit ScrabbleCtrls;

{$mode delphi}
{$WARN 5024 off : Parameter "$1" not used}

interface

uses
  Classes, SysUtils, Controls, Graphics, ExtCtrls, LMessages;

{ TScrabbleBoard }

type
  TScrabbleSquare = (sqNormal, sqDoubleLetter, sqTripleLetter, sqDoubleWord,
    sqTripleWord);

  TScrabbleBoard = class(TCustomControl)
  private
    FCells: array[0..14, 0..14] of Char;
    FBoardSource: TRasterImage;
    FLettersSource: array[1..27] of TRasterImage;
    FBoard: TRasterImage;
    FLetters: array[1..27] of TRasterImage;
    FOffset: TPoint;
    FOffsetActual: TPoint;
    FDragging: Boolean;
    FClicking: Boolean;
    FDrag: TPoint;
    FHotCell: TPoint;
    FAutoScale: Boolean;
    FScaleActual: Single;
    FScaleFactor: Single;
    FScaleChanged: Boolean;
    FSelectCell: TPoint;
    FCaretCell: TPoint;
    FCaretShow: Boolean;
    FEditMode: Boolean;
    FEditRight: Boolean;
    FTimer: TTimer;
    FWords: TStrings;
    procedure ScaleTimeout(Sender: TObject);
    procedure ScaleReset;
    procedure ScaleImages;
    procedure SetAutoScale(Value: Boolean);
    function GetCell(Col, Row: Integer): Char;
    function IsValidCell(Col, Row: Integer): Boolean;
    procedure SetCaretShow(Value: Boolean);
    procedure SetCell(Col, Row: Integer; Value: Char);
    function GetCaretCell: TPoint;
    procedure SetCaretCell(Value: TPoint);
    procedure SetOffset(Value: TPoint);
    procedure SetScaleFactor(Value: Single);
    procedure SetWords(Value: TStrings);
    procedure WordsChange;
    procedure WMGetDlgCode(var Msg: TLMNoParams); message LM_GETDLGCODE;
  protected
    procedure Loaded; override;
    procedure Paint; override;
    procedure DrawLetter(Letter: Char; Cell: TPoint);
    procedure KeyPress(var Key: Char); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function PointToCell(const P: TPoint): TPoint;
    function CellToPoint(const C: TPoint): TPoint;
    function CellToRect(const C: TPoint): TRect;
    property Cells[Col, Row: Integer]: Char read GetCell write SetCell;
    property Offset: TPoint read FOffset write SetOffset;
    property CaretCell: TPoint read GetCaretCell write SetCaretCell;
  published
    property AutoScale: Boolean read FAutoScale write SetAutoScale default True;
    property EditMode: Boolean read FEditMode write FEditMode default True;
    property ScaleFactor: Single read FScaleFactor write SetScaleFactor default 1;
    property CaretShow: Boolean read FCaretShow write SetCaretShow default True;
    property Words: TStrings read FWords write SetWords;
    property Align;
    property Anchors;
    property BorderSpacing;
    property BidiMode;
    property BorderWidth;
    property Color;
    property Constraints;
    property DockSite;
    property DoubleBuffered;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground;
    property ParentBidiMode;
    property ParentColor;
    property ParentDoubleBuffered;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property UseDockManager default True;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDockDrop;
    property OnDockOver;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnGetDockCaption;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnPaint;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
  end;

implementation

uses
  ImageScaling, RtlConsts, LCLType;

{$R scrabblectrls.res}

{ TScrabbleWords }

type
  TScrabbleWords = class(TStrings)
  private
    FBoard: TScrabbleBoard;
    FIndex: Integer;
    FLines: array[0..14] of string;
    FOnChange: TNotifyEvent;
    procedure Change;
  protected
    function Get(Index: Integer): string; override;
    function GetCount: Integer; override;
    procedure SetUpdateState(Updating: Boolean); override;
  public
    constructor Create(Board: TScrabbleBoard);
    procedure Assign(Source: TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index: Integer); override;
    procedure Insert(Index: Integer; const S: string); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

const
  BlankLine = '               ';

constructor TScrabbleWords.Create(Board: TScrabbleBoard);
var
  I: Integer;
begin
  inherited Create;
  FBoard := Board;
  for I := Low(FLines) to High(FLines) do
    FLines[I] := BlankLine;
end;

procedure TScrabbleWords.SetUpdateState(Updating: Boolean);
begin
  inherited;
  if not Updating then
    Change;
end;

procedure TScrabbleWords.Change;
begin
  if UpdateCount = 0 then
  begin
    if Assigned(FOnChange) then
      FOnChange(Self);
    FBoard.WordsChange;
  end;
end;

function TScrabbleWords.Get(Index: Integer): string;
var
  S: string;
  I: Integer;
begin
  Result := BlankLine;
  if (Index < 0) or (Index > 14) then
    Error(SListIndexError, Index);
  S := FLines[Index];
  for I := 1 to Length(S) do
    Result[I] := S[I];
end;

function TScrabbleWords.GetCount: Integer;
begin
  Result := 15;
end;

procedure TScrabbleWords.Assign(Source: TPersistent);
var
  S: TStrings;
  I: Integer;
begin
  if Source is TStrings then
  try
    BeginUpdate;
    S := Source as TStrings;
    Clear;
    for I := 0 to S.Count - 1 do
    begin
      Insert(I, S[I]);
      if I = 14 then
        Break;
    end;
  finally
    EndUpdate;
  end
  else
    inherited Assign(Source);
end;

procedure TScrabbleWords.Clear;
var
  I: Integer;
begin
  for I := Low(FLines) to High(FLines) do
    FLines[I] := BlankLine;
  Change;
end;

procedure TScrabbleWords.Delete(Index: Integer);
begin
  if (Index < 0) or (Index > 14) then
    Error(SListIndexError, Index);
  FLines[Index] := BlankLine;
  Change;
end;

procedure TScrabbleWords.Insert(Index: Integer; const S: string);
var
  L: string;
  C: Char;
  I: Integer;
begin
  if csLoading in FBoard.ComponentState then
  begin
    Index := FIndex;
    Inc(FIndex);
    if (Index < 0) or (Index > 14) then
      Exit;
  end
  else if (Index < 0) or (Index > 14) then
    Error(SListIndexError, Index);
  L := BlankLine;
  for I := 1 to Length(S) do
  begin
    C := UpCase(S[I]);
    if C in ['_', 'A'..'Z'] then
      L[I] := C
    else
      L[I] := ' ';
    if I = 15 then
      Break;
  end;
  FLines[Index] := L;
  Change;
end;

{ TScrabbleBoard }

const
  TileX = 71;
  TileY = 77;
  MarginX = 180;
  MarginY = 134;
  DeltaX = 77.55;
  DeltaY = 82.90;
  Letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ_';

constructor TScrabbleBoard.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 500;
  Height := 500;
  FAutoScale := True;
  FCaretShow := True;
  FEditMode := True;
  FEditRight := True;
  FSelectCell := Point(-1, -1);
  FHotCell := Point(-1, -1);
  FTimer := TTimer.Create(Self);
  FTimer.Enabled := False;
  FTimer.Interval := 50;
  FTimer.OnTimer := ScaleTimeout;
  FScaleFactor := 1;
  FScaleActual := FScaleFactor;
  FScaleChanged := True;
  FWords := TScrabbleWords.Create(Self);
  Clear;
end;

destructor TScrabbleBoard.Destroy;
var
  I: Integer;
begin
  FWords.Free;
  FBoardSource.Free;
  for I := 1 to Length(Letters) do
    FLettersSource[I].Free;
  inherited Destroy;
end;

procedure TScrabbleBoard.Loaded;
begin
  inherited;
  FTimer.Enabled := False;
  ScaleTimeout(nil);
  WordsChange;
  Invalidate;
end;

procedure TScrabbleBoard.WordsChange;
var
  I, J: Integer;
  S: string;
begin
  for I := 0 to 14 do
  begin
    S := FWords[I];
    for J := 1 to Length(S) do
      FCells[J - 1, I] := S[J];
  end;
  Invalidate;
end;

procedure TScrabbleBoard.SetWords(Value: TStrings);
begin
  FWords.Assign(Value);
end;

procedure TScrabbleBoard.ScaleImages;
var
  I: Integer;
begin
  if not FScaleChanged then Exit;
  FScaleChanged := False;
  FBoard.Free;
  for I := 1 to Length(Letters) do
    FLetters[I].Free;
  if FScaleActual = 1 then
  begin
    FBoard := NewBitmap;
    FBoard.Assign(FBoardSource);
    for I := 1 to Length(Letters) do
    begin
      FLetters[I] := NewBitmap;
      FLetters[I].Assign(FLettersSource[I]);
    end;
  end
  else
  begin
    FBoard := ResampleBitmap(FBoardSource, Round(FBoardSource.Width * FScaleActual),
      Round(FBoardSource.Height * FScaleActual)) as TRasterImage;
    for I := 1 to Length(Letters) do
    begin
      FLetters[I] := ResampleBitmap(FLettersSource[I], Round(FLettersSource[I].Width * FScaleActual),
        Round(FLettersSource[I].Height * FScaleActual)) as TRasterImage;
    end;
  end;
end;

procedure TScrabbleBoard.ScaleReset;
begin
  FTimer.Enabled := False;
  FTimer.Enabled := True;
end;

procedure TScrabbleBoard.ScaleTimeout(Sender: TObject);
const
  MinScale = 0.1;
var
  W, H: Integer;
  S: Single;
  I: Integer;
begin
  FTimer.Enabled := False;
  if FBoardSource = nil then
  begin
    FBoardSource := NewBitmap;
    FBoardSource.LoadFromResourceName(HINSTANCE, 'scrabble_board');
  end;
  for I := 1 to Length(Letters) do
  begin
    FLettersSource[I] := NewBitmap;
    FLettersSource[I].LoadFromResourceName(HINSTANCE, 'scrabble_' + Letters[I]);
  end;
  S := FScaleActual;
  if FAutoScale then
  begin
    Tag := Tag + 1;
    W := Width;
    H := Height;
    if (W > FBoardSource.Width) and (H > FBoardSource.Height) then
    begin
      S := 1;
      FOffsetActual.X := Round(W - FBoardSource.Width) div 2;
      FOffsetActual.Y := Round(H - FBoardSource.Height) div 2;
    end
    else if (W / FBoardSource.Width > H / FBoardSource.Height) then
    begin
      S := H / FBoardSource.Height;
      if S < MinScale then
        S := MinScale;
      FOffsetActual.Y := 0;
      FOffsetActual.X := Round(W - S * FBoardSource.Width) div 2;
    end
    else
    begin
      S := W / FBoardSource.Width;
      if S < MinScale then
        S := MinScale;
      FOffsetActual.X := 0;
      FOffsetActual.Y := Round(H - S * FBoardSource.Height) div 2;
    end;
  end
  else
  begin
    S := FScaleFactor;
    FOffsetActual := FOffset;
  end;
  FScaleChanged := FScaleActual <> S;
  FScaleActual := S;
  Invalidate;
end;

procedure TScrabbleBoard.Clear;
begin
  FWords.Clear;
end;

function PointInRect(const P: TPoint; const R: TRect): Boolean;
begin
  Result := (P.X >= R.Left) and (P.Y >= R.Top) and (P.X < R.Right) and (P.Y < R.Bottom);
end;

function TScrabbleBoard.PointToCell(const P: TPoint): TPoint;
var
  X, Y: Integer;
  C: TPoint;
  R: TRect;
begin
  for X := 0 to 14 do
    for Y := 0 to 14 do
    begin
      C := Point(X, Y);
      R := CellToRect(C);
      if PointInRect(P, R) then
        Exit(C);
    end;
  Result.X := -1;
  Result.Y := -1;
end;

function TScrabbleBoard.CellToPoint(const C: TPoint): TPoint;
begin
  Result := CellToRect(C).TopLeft;
end;

function TScrabbleBoard.CellToRect(const C: TPoint): TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Width := 0;
  Result.Height := 0;
  if (C.X < 0) or (C.Y < 0) or (C.X > 14)  or (C.Y > 14) then
    Exit;
  Result.Left := Round(FOffsetActual.X + (MarginX + C.X * DeltaX) * FScaleActual);
  Result.Top := Round(FOffsetActual.Y + (MarginY + C.Y * DeltaY) * FScaleActual);
  Result.Width := Round(TileX * FScaleActual);
  Result.Height := Round(TileY * FScaleActual);
end;

procedure TScrabbleBoard.DrawLetter(Letter: Char; Cell: TPoint);
var
  P: TPoint;
begin
  if (Cell.X < 0) or (Cell.Y < 0) or (Cell.X > 14)  or (Cell.Y > 14) then
    Exit;
  P := CellToPoint(Cell);
  if Letter in ['A'..'Z'] then
    Canvas.Draw(P.X, P.Y - 1, FLetters[Ord(Letter) - Ord('A') + 1])
  else if Letter = '_' then
    Canvas.Draw(P.X, P.Y - 1, FLetters[High(FLetters)]);
end;

procedure TScrabbleBoard.KeyPress(var Key: Char);
var
  P: TPoint;
begin
  inherited KeyPress(Key);
  P := FCaretCell;
  if IsValidCell(P.X, P.Y) and FEditMode and FCaretShow and (Key in [' ', '_', 'A'..'Z', 'a'..'z']) then
  begin
    Cells[FCaretCell.X, FCaretCell.Y] := Key;
    if FEditRight then
      Inc(P.X)
    else
      Inc(P.Y);
    if IsValidCell(P.X, P.Y) then
      CaretCell := P;
  end;
end;

procedure TScrabbleBoard.KeyDown(var Key: Word; Shift: TShiftState);
var
  P: TPoint;
begin
  inherited;
  if not FEditMode then
    Exit;
  if Key = VK_ESCAPE then
    Clear
  else if FCaretShow then
  begin
    P := CaretCell;
    case Key of
      VK_BACK:
        begin
          Cells[P.X, P.Y] := ' ';
          if FEditRight then
            Dec(P.X)
          else
            Dec(P.Y);
        end;
      VK_LEFT:
        begin
          FEditRight := True;
          Dec(P.X);
        end;
      VK_RIGHT:
        begin
          FEditRight := True;
          Inc(P.X);
        end;
      VK_UP:
        begin
          FEditRight := False;
          Dec(P.Y);
        end;
      VK_DOWN:
        begin
          FEditRight := False;
          Inc(P.Y);
        end;
    end;
    if IsValidCell(P.X, P.Y) then
      CaretCell := P;
    SetFocus;
  end;
end;

procedure TScrabbleBoard.Paint;
var
  X, Y: Integer;
begin
  inherited Paint;
  ScaleImages;
  if FBoard = nil then
    Exit;
  Canvas.Draw(FOffsetActual.X, FOffsetActual.Y, FBoard);
  Canvas.Pen.Width := 3;
  Canvas.Brush.Style := bsClear;
  if FCaretShow then
  begin
    Canvas.Pen.Color := clGreen;
    Canvas.Rectangle(CellToRect(FCaretCell));
  end;
  Canvas.Pen.Color := clLime;
  Canvas.Rectangle(CellToRect(FHotCell));
  for X := Low(FCells) to High(FCells) do
    for Y := Low(FCells[X]) to High(FCells[X]) do
      DrawLetter(FCells[X, Y], Point(X, Y));
end;

procedure TScrabbleBoard.MouseDown(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  FDragging := (Shift = [ssLeft, ssShift]) or (Button = mbMiddle);
  if FDragging then
  begin
    FDrag.X := X;
    FDrag.Y := Y;
  end
  else
  begin
    FClicking := True;
    FSelectCell := PointToCell(Point(X, Y));
  end;
end;

procedure TScrabbleBoard.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  C: TPoint;
begin
  inherited MouseMove(Shift, X, Y);
  if FDragging then
  begin
    FOffsetActual.X := FOffsetActual.X + X - FDrag.X;
    FOffsetActual.Y := FOffsetActual.Y + Y - FDrag.Y;
    FDrag.X := X;
    FDrag.Y := Y;
    Invalidate;
  end
  else
  begin
    C := PointToCell(Point(X, Y));
    if (C.X <> FHotCell.X) or (C.Y <> FHotCell.Y) then
    begin
      FHotCell := C;
      Invalidate;
    end;
  end;
end;

procedure TScrabbleBoard.MouseUp(Button: TMouseButton; Shift: TShiftState; X,
  Y: Integer);
var
  P: TPoint;
begin
  inherited MouseUp(Button, Shift, X, Y);
  FDragging := False;
  if FClicking then
  begin
    FClicking := False;
    P := PointToCell(Point(X, Y));
    if P.X < 0 then
      Exit;
    if (P.X = FSelectCell.X) and (P.Y = FSelectCell.Y) then
    begin
      FSelectCell := P;
      if (FCaretCell.X = FSelectCell.X) and (FCaretCell.Y = FSelectCell.Y) then
        FCaretShow := not FCaretShow
      else
        FCaretShow := True;
      FCaretCell := FSelectCell;
      Invalidate;
    end;
  end;
end;

function TScrabbleBoard.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
const
  Step = 0.1;
begin
  Result := inherited;
  if FAutoScale then
    Exit;
  if ssCtrl in Shift then
    if WheelDelta < 0 then
      ScaleFactor := ScaleFactor - Step
    else
      ScaleFactor := ScaleFactor + Step;
end;

procedure TScrabbleBoard.Resize;
begin
  inherited;
  if FAutoScale then
    ScaleReset;
end;

function TScrabbleBoard.IsValidCell(Col, Row: Integer): Boolean;
begin
  Result := False;
  if (Col < 0) or (Row < 0) then
    Exit;
  if (Col > 14) or (Row > 14) then
    Exit;
  Result := True;
end;

procedure TScrabbleBoard.SetCaretShow(Value: Boolean);
begin
  if FCaretShow <> Value then
  begin
    FCaretShow := Value;
    Invalidate;
  end;
end;

procedure TScrabbleBoard.SetAutoScale(Value: Boolean);
begin
  if Value <> FAutoScale then
  begin
    FAutoScale := Value;
    ScaleReset;
  end;
end;

function TScrabbleBoard.GetCell(Col, Row: Integer): Char;
begin
  Result := ' ';
  if IsValidCell(Col, Row) then
    Result := FCells[Col, Row];
end;

procedure TScrabbleBoard.SetCell(Col, Row: Integer; Value: Char);
var
  W: TScrabbleWords;
begin
  if not IsValidCell(Col, Row) then
    Exit;
  Value := UpCase(Value);
  if Value in [' ', '_', 'A'..'Z'] then
  begin
    FCells[Col, Row] := Value;
    W := TScrabbleWords(FWords);
    W.FLines[Row][Col + 1] := Value;
    if Assigned(W.OnChange) then
      W.OnChange(W);
  end;
  Invalidate;
end;

function TScrabbleBoard.GetCaretCell: TPoint;
begin
  Result := FCaretCell;
end;

procedure TScrabbleBoard.SetCaretCell(Value: TPoint);
begin
  if (Value.X = FCaretCell.X) and (Value.Y = FCaretCell.Y) then
    Exit;
  if IsValidCell(Value.X, Value.Y) then
  begin
    FCaretCell := Value;
    FCaretShow := True;
  end
  else
    FCaretShow := False;
  Invalidate;
end;

procedure TScrabbleBoard.SetOffset(Value: TPoint);
begin
  if (Value.X = FOffset.X) and (Value.Y = FOffset.Y) then
    Exit;
  FOffset := Value;
  if not FAutoScale then
  begin
    FOffsetActual := FOffset;
    Invalidate;
  end;
end;

procedure TScrabbleBoard.SetScaleFactor(Value: Single);
const
  Min = 0.1;
  Max = 1.0;
begin
  if Value < Min then
    Value := Min
  else if Value > Max then
    Value := Max;
  if FScaleFactor <> Value then
  begin
    FScaleFactor := Value;
    ScaleReset;
  end;
end;

procedure TScrabbleBoard.WMGetDlgCode(var Msg: TLMNoParams);
begin
  Msg.Result := DLGC_WANTARROWS or DLGC_WANTCHARS;
end;

end.

