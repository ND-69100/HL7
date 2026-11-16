unit uHL7Extract;

interface

uses
  System.SysUtils, System.Classes, uHL7;

const
  CSVSeparateur = ';';
  CSVEntete = 'Fichier;TypeMessage;DateMessage;Expediteur;Destinataire;PatientID;Nom;Prenom;DateNaissance;Sexe;Visite;CodeExamen;Examen;DateExamen;Observation;Valeur;Unites;Reference;Statut';

type
  THL7LigneExtraction = record
    Fichier: string;
    TypeMessage: string;
    DateMessage: string;
    Expediteur: string;
    Destinataire: string;
    PatientID: string;
    Nom: string;
    Prenom: string;
    DateNaissance: string;
    Sexe: string;
    Visite: string;
    CodeExamen: string;
    Examen: string;
    DateExamen: string;
    Observation: string;
    Valeur: string;
    Unites: string;
    Reference: string;
    Statut: string;
  end;

function ExtraireLignes(const Msg: THL7Message; const NomFichier: string): TArray<THL7LigneExtraction>;
procedure ExtraireResume(const Msg: THL7Message; const NomFichier: string; Lignes: TStrings);
procedure ExporterCSV(const Fichiers: TStrings; const NomCSV: string);
function CSVChamp(const Valeur: string): string;

implementation

function NombreSegments(const Msg: THL7Message; const Nom: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to Msg.Segments.Count - 1 do
    if SameText(Msg.Segments[I].Name, Nom) then
      Inc(Result);
end;

function ExtraireLignes(const Msg: THL7Message; const NomFichier: string): TArray<THL7LigneExtraction>;
var
  MSH, PID, PV1, OBR: THL7Segment;
  Base: THL7LigneExtraction;
  I, N: Integer;
begin
  SetLength(Result, 0);
  MSH := Msg.FirstSegment('MSH');
  PID := Msg.FirstSegment('PID');
  PV1 := Msg.FirstSegment('PV1');
  OBR := Msg.FirstSegment('OBR');
  Base.Fichier := NomFichier;
  if MSH <> nil then
  begin
    Base.TypeMessage := MSH.Field(9);
    Base.DateMessage := MSH.Field(7);
    Base.Expediteur := MSH.Field(3) + ' / ' + MSH.Field(4);
    Base.Destinataire := MSH.Field(5) + ' / ' + MSH.Field(6);
  end;
  if PID <> nil then
  begin
    Base.PatientID := PID.Field(3);
    Base.Nom := PID.Component(5, 1);
    Base.Prenom := PID.Component(5, 2);
    Base.DateNaissance := PID.Field(7);
    Base.Sexe := PID.Field(8);
  end;
  if PV1 <> nil then
  begin
    Base.Visite := PV1.Field(19);
    if Base.Visite = '' then
      Base.Visite := PV1.Field(2);
  end;
  if OBR <> nil then
  begin
    Base.CodeExamen := OBR.Component(4, 1);
    Base.Examen := OBR.Component(4, 2);
    Base.DateExamen := OBR.Field(7);
  end;
  N := 0;
  for I := 0 to Msg.Segments.Count - 1 do
    if SameText(Msg.Segments[I].Name, 'OBX') then
    begin
      SetLength(Result, N + 1);
      Result[N] := Base;
      Result[N].Observation := Msg.Segments[I].Field(3);
      Result[N].Valeur := Msg.Segments[I].Field(5);
      Result[N].Unites := Msg.Segments[I].Field(6);
      Result[N].Reference := Msg.Segments[I].Field(7);
      Result[N].Statut := Msg.Segments[I].Field(11);
      Inc(N);
    end;
  if N = 0 then
  begin
    SetLength(Result, 1);
    Result[0] := Base;
  end;
end;

procedure ExtraireResume(const Msg: THL7Message; const NomFichier: string; Lignes: TStrings);
var
  MSH, PID, PV1, OBR: THL7Segment;
  LignesExtraction: TArray<THL7LigneExtraction>;
  I: Integer;
begin
  Lignes.BeginUpdate;
  try
    Lignes.Clear;
    Lignes.Add('Fichier : ' + NomFichier);
    MSH := Msg.FirstSegment('MSH');
    if MSH <> nil then
    begin
      Lignes.Add('Type de message (MSH-9) : ' + MSH.Field(9));
      Lignes.Add('Date du message (MSH-7) : ' + MSH.Field(7));
      Lignes.Add('Expediteur (MSH-3 / MSH-4) : ' + MSH.Field(3) + ' / ' + MSH.Field(4));
      Lignes.Add('Destinataire (MSH-5 / MSH-6) : ' + MSH.Field(5) + ' / ' + MSH.Field(6));
    end;
    PID := Msg.FirstSegment('PID');
    if PID <> nil then
    begin
      Lignes.Add('');
      Lignes.Add('Patient (PID)');
      Lignes.Add('  Identifiant (PID-3) : ' + PID.Field(3));
      Lignes.Add('  Nom (PID-5) : ' + PID.Field(5));
      Lignes.Add('  Date de naissance (PID-7) : ' + PID.Field(7));
      Lignes.Add('  Sexe (PID-8) : ' + PID.Field(8));
    end;
    PV1 := Msg.FirstSegment('PV1');
    if PV1 <> nil then
    begin
      Lignes.Add('');
      Lignes.Add('Visite (PV1)');
      Lignes.Add('  Classe (PV1-2) : ' + PV1.Field(2));
      Lignes.Add('  Numero de visite (PV1-19) : ' + PV1.Field(19));
    end;
    OBR := Msg.FirstSegment('OBR');
    if OBR <> nil then
    begin
      Lignes.Add('');
      Lignes.Add('Examen (OBR)');
      Lignes.Add('  Code (OBR-4.1) : ' + OBR.Component(4, 1));
      Lignes.Add('  Libelle (OBR-4.2) : ' + OBR.Component(4, 2));
      Lignes.Add('  Date (OBR-7) : ' + OBR.Field(7));
    end;
    Lignes.Add('');
    Lignes.Add(Format('Observations (OBX) : %d', [NombreSegments(Msg, 'OBX')]));
    LignesExtraction := ExtraireLignes(Msg, NomFichier);
    for I := Low(LignesExtraction) to High(LignesExtraction) do
      Lignes.Add(Format('  [%d] %s = %s %s (reference : %s, statut : %s)', [I + 1,
        LignesExtraction[I].Observation, LignesExtraction[I].Valeur, LignesExtraction[I].Unites,
        LignesExtraction[I].Reference, LignesExtraction[I].Statut]));
  finally
    Lignes.EndUpdate;
  end;
end;

function CSVChamp(const Valeur: string): string;
begin
  if (Pos(CSVSeparateur, Valeur) > 0) or (Pos('"', Valeur) > 0) or
     (Pos(#13, Valeur) > 0) or (Pos(#10, Valeur) > 0) then
    Result := '"' + StringReplace(Valeur, '"', '""', [rfReplaceAll]) + '"'
  else
    Result := Valeur;
end;

function LigneCSV(const L: THL7LigneExtraction): string;
begin
  Result := CSVChamp(L.Fichier) + CSVSeparateur +
    CSVChamp(L.TypeMessage) + CSVSeparateur +
    CSVChamp(L.DateMessage) + CSVSeparateur +
    CSVChamp(L.Expediteur) + CSVSeparateur +
    CSVChamp(L.Destinataire) + CSVSeparateur +
    CSVChamp(L.PatientID) + CSVSeparateur +
    CSVChamp(L.Nom) + CSVSeparateur +
    CSVChamp(L.Prenom) + CSVSeparateur +
    CSVChamp(L.DateNaissance) + CSVSeparateur +
    CSVChamp(L.Sexe) + CSVSeparateur +
    CSVChamp(L.Visite) + CSVSeparateur +
    CSVChamp(L.CodeExamen) + CSVSeparateur +
    CSVChamp(L.Examen) + CSVSeparateur +
    CSVChamp(L.DateExamen) + CSVSeparateur +
    CSVChamp(L.Observation) + CSVSeparateur +
    CSVChamp(L.Valeur) + CSVSeparateur +
    CSVChamp(L.Unites) + CSVSeparateur +
    CSVChamp(L.Reference) + CSVSeparateur +
    CSVChamp(L.Statut);
end;

procedure ExporterCSV(const Fichiers: TStrings; const NomCSV: string);
var
  Sortie: TStringList;
  I, J: Integer;
  Msg: THL7Message;
  Lignes: TArray<THL7LigneExtraction>;
begin
  Sortie := TStringList.Create;
  try
    Sortie.Add(CSVEntete);
    for I := 0 to Fichiers.Count - 1 do
    begin
      Msg := THL7Message.Create;
      try
        Msg.LoadFromFile(Fichiers[I]);
        Lignes := ExtraireLignes(Msg, ExtractFileName(Fichiers[I]));
        for J := Low(Lignes) to High(Lignes) do
          Sortie.Add(LigneCSV(Lignes[J]));
      finally
        Msg.Free;
      end;
    end;
    Sortie.SaveToFile(NomCSV, TEncoding.UTF8);
  finally
    Sortie.Free;
  end;
end;

end.
