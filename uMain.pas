unit uMain;

interface

uses
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls,
  uHL7, uHL7Extract;

type
  TFormMain = class(TForm)
    pnlTop: TPanel;
    lblDossier: TLabel;
    edtDossier: TEdit;
    btnParcourir: TButton;
    btnRafraichir: TButton;
    chkSurveiller: TCheckBox;
    pnlLeft: TPanel;
    lblFichiers: TLabel;
    lstFichiers: TListBox;
    splVertical: TSplitter;
    pnlClient: TPanel;
    pnlBoutons: TPanel;
    btnExporter: TButton;
    btnExporterTout: TButton;
    pgc: TPageControl;
    tsArbo: TTabSheet;
    tvMessage: TTreeView;
    tsDonnees: TTabSheet;
    memoDonnees: TMemo;
    sbStatus: TStatusBar;
    tmrSurveillance: TTimer;
    dlgOuvrirDossier: TFileOpenDialog;
    dlgSauver: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnParcourirClick(Sender: TObject);
    procedure btnRafraichirClick(Sender: TObject);
    procedure chkSurveillerClick(Sender: TObject);
    procedure lstFichiersClick(Sender: TObject);
    procedure tmrSurveillanceTimer(Sender: TObject);
    procedure btnExporterClick(Sender: TObject);
    procedure btnExporterToutClick(Sender: TObject);
  private
    FMessage: THL7Message;
    function FichierSelectionne: string;
    procedure RafraichirListeFichiers;
    procedure ChargerFichier(const NomFichier: string);
    procedure RemplirArborescence;
    procedure RemplirExtraction;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

procedure TFormMain.FormCreate(Sender: TObject);
var
  Dossier: string;
begin
  FMessage := THL7Message.Create;
  Dossier := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  if DirectoryExists(Dossier + 'HL7') then
    Dossier := IncludeTrailingPathDelimiter(Dossier + 'HL7');
  edtDossier.Text := Dossier;
  RafraichirListeFichiers;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  FMessage.Free;
end;

function TFormMain.FichierSelectionne: string;
begin
  Result := '';
  if lstFichiers.ItemIndex >= 0 then
    Result := IncludeTrailingPathDelimiter(edtDossier.Text) + lstFichiers.Items[lstFichiers.ItemIndex];
end;

procedure TFormMain.RafraichirListeFichiers;
var
  Dossier: string;
  Recherche: TSearchRec;
  Liste: TStringList;
  Selection: string;
begin
  Selection := FichierSelectionne;
  Liste := TStringList.Create;
  Liste.Sorted := True;
  Liste.Duplicates := dupIgnore;
  try
    Dossier := IncludeTrailingPathDelimiter(edtDossier.Text);
    if FindFirst(Dossier + '*.hl7', faAnyFile, Recherche) = 0 then
    begin
      repeat
        if (Recherche.Attr and faDirectory) = 0 then
          Liste.Add(Recherche.Name);
      until FindNext(Recherche) <> 0;
      FindClose(Recherche);
    end;
    lstFichiers.Items.BeginUpdate;
    try
      lstFichiers.Items.Assign(Liste);
      if Selection <> '' then
        lstFichiers.ItemIndex := lstFichiers.Items.IndexOf(ExtractFileName(Selection));
    finally
      lstFichiers.Items.EndUpdate;
    end;
    sbStatus.SimpleText := Format('%d fichier(s) HL7 dans %s', [lstFichiers.Items.Count, Dossier]);
    if (Selection = '') and (lstFichiers.Items.Count > 0) then
    begin
      lstFichiers.ItemIndex := 0;
      ChargerFichier(FichierSelectionne);
    end;
  finally
    Liste.Free;
  end;
end;

procedure TFormMain.btnParcourirClick(Sender: TObject);
begin
  dlgOuvrirDossier.FileName := edtDossier.Text;
  if dlgOuvrirDossier.Execute then
  begin
    edtDossier.Text := dlgOuvrirDossier.FileName;
    RafraichirListeFichiers;
  end;
end;

procedure TFormMain.btnRafraichirClick(Sender: TObject);
begin
  RafraichirListeFichiers;
end;

procedure TFormMain.chkSurveillerClick(Sender: TObject);
begin
  tmrSurveillance.Enabled := chkSurveiller.Checked;
end;

procedure TFormMain.tmrSurveillanceTimer(Sender: TObject);
begin
  RafraichirListeFichiers;
end;

procedure TFormMain.lstFichiersClick(Sender: TObject);
begin
  if FichierSelectionne <> '' then
    ChargerFichier(FichierSelectionne);
end;

procedure TFormMain.ChargerFichier(const NomFichier: string);
begin
  try
    FMessage.LoadFromFile(NomFichier);
    RemplirArborescence;
    RemplirExtraction;
    sbStatus.SimpleText := Format('%s : %d segment(s)', [ExtractFileName(NomFichier), FMessage.Segments.Count]);
  except
    on E: Exception do
      MessageDlg(Format('Erreur lors de la lecture de %s'#13#10'%s', [NomFichier, E.Message]), mtError, [mbOK], 0);
  end;
end;

procedure TFormMain.RemplirArborescence;
var
  I, J, K: Integer;
  Seg: THL7Segment;
  Racine, Champ: TTreeNode;
  Composants: TStringDynArray;
begin
  tvMessage.Items.BeginUpdate;
  try
    tvMessage.Items.Clear;
    for I := 0 to FMessage.Segments.Count - 1 do
    begin
      Seg := FMessage.Segments[I];
      Racine := tvMessage.Items.Add(nil, Format('%s (%d champs)', [Seg.Name, Seg.FieldCount - 1]));
      for J := 1 to Seg.FieldCount - 1 do
        if Seg.Field(J) <> '' then
        begin
          Champ := tvMessage.Items.AddChild(Racine, Format('%s-%d : %s', [Seg.Name, J, Seg.Field(J)]));
          Composants := Split(Seg.Field(J), FMessage.CompSep);
          if Length(Composants) > 1 then
            for K := Low(Composants) to High(Composants) do
              tvMessage.Items.AddChild(Champ, Format('composant %d : %s', [K + 1, Composants[K]]));
        end;
    end;
    tvMessage.FullExpand;
  finally
    tvMessage.Items.EndUpdate;
  end;
end;

procedure TFormMain.RemplirExtraction;
var
  Lignes: TStringList;
begin
  Lignes := TStringList.Create;
  try
    ExtraireResume(FMessage, ExtractFileName(FichierSelectionne), Lignes);
    memoDonnees.Lines.Assign(Lignes);
  finally
    Lignes.Free;
  end;
end;

procedure TFormMain.btnExporterClick(Sender: TObject);
var
  Fichiers: TStringList;
begin
  if FichierSelectionne = '' then
  begin
    MessageDlg('Selectionnez d''abord un fichier dans la liste.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if dlgSauver.Execute then
  begin
    Fichiers := TStringList.Create;
    try
      Fichiers.Add(FichierSelectionne);
      ExporterCSV(Fichiers, dlgSauver.FileName);
      MessageDlg(Format('Export realise : %s', [dlgSauver.FileName]), mtInformation, [mbOK], 0);
    finally
      Fichiers.Free;
    end;
  end;
end;

procedure TFormMain.btnExporterToutClick(Sender: TObject);
var
  Fichiers: TStringList;
  I: Integer;
  Dossier: string;
begin
  if lstFichiers.Items.Count = 0 then
  begin
    MessageDlg('Aucun fichier HL7 dans le dossier surveille.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if dlgSauver.Execute then
  begin
    Fichiers := TStringList.Create;
    try
      Dossier := IncludeTrailingPathDelimiter(edtDossier.Text);
      for I := 0 to lstFichiers.Items.Count - 1 do
        Fichiers.Add(Dossier + lstFichiers.Items[I]);
      ExporterCSV(Fichiers, dlgSauver.FileName);
      MessageDlg(Format('Export de %d fichier(s) realise : %s', [Fichiers.Count, dlgSauver.FileName]), mtInformation, [mbOK], 0);
    finally
      Fichiers.Free;
    end;
  end;
end;

end.
