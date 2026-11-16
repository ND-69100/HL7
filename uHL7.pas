unit uHL7;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  THL7Segment = class
  private
    FName: string;
    FFields: TStringList;
    FCompSep: Char;
  public
    constructor Create(const ALine: string; AFieldSep, ACompSep: Char; AIsMSH: Boolean);
    destructor Destroy; override;
    property Name: string read FName;
    function Field(Index: Integer): string;
    function Component(FieldIndex, CompIndex: Integer): string;
    function FieldCount: Integer;
  end;

  THL7Message = class
  private
    FSegments: TObjectList<THL7Segment>;
    FFieldSep: Char;
    FCompSep: Char;
    FRepSep: Char;
    FEscChar: Char;
    FSubCompSep: Char;
  public
    constructor Create;
    destructor Destroy; override;
    property Segments: TObjectList<THL7Segment> read FSegments;
    property FieldSep: Char read FFieldSep;
    property CompSep: Char read FCompSep;
    property RepSep: Char read FRepSep;
    property EscChar: Char read FEscChar;
    property SubCompSep: Char read FSubCompSep;
    procedure LoadFromFile(const FileName: string);
    procedure Parse(const Text: string);
    function FirstSegment(const AName: string): THL7Segment;
    function GetField(const ASegName: string; AFieldIndex: Integer): string;
  end;

function Split(const S: string; Sep: Char): TStringDynArray;

implementation

function Split(const S: string; Sep: Char): TStringDynArray;
var
  I, Debut, N: Integer;
begin
  SetLength(Result, 0);
  Debut := 1;
  N := 0;
  for I := 1 to Length(S) do
    if S[I] = Sep then
    begin
      SetLength(Result, N + 1);
      Result[N] := Copy(S, Debut, I - Debut);
      Inc(N);
      Debut := I + 1;
    end;
  SetLength(Result, N + 1);
  Result[N] := Copy(S, Debut, Length(S) - Debut + 1);
end;

constructor THL7Segment.Create(const ALine: string; AFieldSep, ACompSep: Char; AIsMSH: Boolean);
var
  Parties: TStringDynArray;
  I: Integer;
begin
  inherited Create;
  FCompSep := ACompSep;
  FFields := TStringList.Create;
  Parties := Split(ALine, AFieldSep);
  if Length(Parties) > 0 then
    FName := Parties[0]
  else
    FName := '';
  FFields.Add(FName);
  if AIsMSH then
    FFields.Add(AFieldSep);
  for I := 1 to High(Parties) do
    FFields.Add(Parties[I]);
end;

destructor THL7Segment.Destroy;
begin
  FFields.Free;
  inherited Destroy;
end;

function THL7Segment.Field(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FFields.Count) then
    Result := FFields[Index]
  else
    Result := '';
end;

function THL7Segment.FieldCount: Integer;
begin
  Result := FFields.Count;
end;

function THL7Segment.Component(FieldIndex, CompIndex: Integer): string;
var
  Composants: TStringDynArray;
begin
  Composants := Split(Field(FieldIndex), FCompSep);
  if (CompIndex >= 1) and (CompIndex <= Length(Composants)) then
    Result := Composants[CompIndex - 1]
  else
    Result := '';
end;

constructor THL7Message.Create;
begin
  inherited Create;
  FSegments := TObjectList<THL7Segment>.Create(True);
  FFieldSep := '|';
  FCompSep := '^';
  FRepSep := '~';
  FEscChar := '\';
  FSubCompSep := '&';
end;

destructor THL7Message.Destroy;
begin
  FSegments.Free;
  inherited Destroy;
end;

procedure THL7Message.LoadFromFile(const FileName: string);
var
  Flux: TFileStream;
  Octets: TBytes;
  Encodage: TEncoding;
begin
  Flux := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(Octets, Flux.Size);
    if Flux.Size > 0 then
      Flux.ReadBuffer(Octets[0], Flux.Size);
  finally
    Flux.Free;
  end;
  if (Length(Octets) >= 3) and (Octets[0] = $EF) and (Octets[1] = $BB) and (Octets[2] = $BF) then
    Encodage := TEncoding.UTF8
  else if (Length(Octets) >= 2) and (Octets[0] = $FF) and (Octets[1] = $FE) then
    Encodage := TEncoding.Unicode
  else if (Length(Octets) >= 2) and (Octets[0] = $FE) and (Octets[1] = $FF) then
    Encodage := TEncoding.BigEndianUnicode
  else
    Encodage := TEncoding.Default;
  Parse(Encodage.GetString(Octets));
end;

procedure THL7Message.Parse(const Text: string);
var
  Normalise: string;
  Lignes: TStringList;
  I: Integer;
  Ligne: string;
  LigneMSH: string;
  Parties: TStringDynArray;
begin
  FSegments.Clear;
  Normalise := StringReplace(Text, #11, #13, [rfReplaceAll]);
  Normalise := StringReplace(Normalise, #28, #13, [rfReplaceAll]);
  Lignes := TStringList.Create;
  try
    Lignes.Text := Normalise;
    LigneMSH := '';
    for I := 0 to Lignes.Count - 1 do
      if Copy(Lignes[I], 1, 3) = 'MSH' then
      begin
        LigneMSH := Lignes[I];
        Break;
      end;
    if LigneMSH = '' then
      Exit;
    if Length(LigneMSH) >= 4 then
      FFieldSep := LigneMSH[4]
    else
      FFieldSep := '|';
    Parties := Split(LigneMSH, FFieldSep);
    if Length(Parties) >= 2 then
    begin
      if Length(Parties[1]) >= 1 then FCompSep := Parties[1][1];
      if Length(Parties[1]) >= 2 then FRepSep := Parties[1][2];
      if Length(Parties[1]) >= 3 then FEscChar := Parties[1][3];
      if Length(Parties[1]) >= 4 then FSubCompSep := Parties[1][4];
    end;
    for I := 0 to Lignes.Count - 1 do
    begin
      Ligne := TrimRight(Lignes[I]);
      if Ligne <> '' then
        FSegments.Add(THL7Segment.Create(Ligne, FFieldSep, FCompSep, Copy(Ligne, 1, 3) = 'MSH'));
    end;
  finally
    Lignes.Free;
  end;
end;

function THL7Message.FirstSegment(const AName: string): THL7Segment;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FSegments.Count - 1 do
    if SameText(FSegments[I].Name, AName) then
      Exit(FSegments[I]);
end;

function THL7Message.GetField(const ASegName: string; AFieldIndex: Integer): string;
var
  Seg: THL7Segment;
begin
  Seg := FirstSegment(ASegName);
  if Seg <> nil then
    Result := Seg.Field(AFieldIndex)
  else
    Result := '';
end;

end.
