object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'Transmission HL7'
  ClientHeight = 620
  ClientWidth = 980
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 980
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblDossier: TLabel
      Left = 8
      Top = 12
      Width = 122
      Height = 13
      Caption = 'Dossier des fichiers HL7 :'
    end
    object edtDossier: TEdit
      Left = 136
      Top = 9
      Width = 430
      Height = 21
      TabOrder = 0
    end
    object btnParcourir: TButton
      Left = 572
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Parcourir...'
      TabOrder = 1
      OnClick = btnParcourirClick
    end
    object btnRafraichir: TButton
      Left = 668
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Rafraichir'
      TabOrder = 2
      OnClick = btnRafraichirClick
    end
    object chkSurveiller: TCheckBox
      Left = 768
      Top = 12
      Width = 140
      Height = 17
      Caption = 'Surveiller le dossier'
      TabOrder = 3
      OnClick = chkSurveillerClick
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 41
    Width = 280
    Height = 556
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object lblFichiers: TLabel
      Left = 0
      Top = 0
      Width = 280
      Height = 17
      Align = alTop
      Caption = '  Fichiers HL7 du dossier'
    end
    object lstFichiers: TListBox
      Left = 8
      Top = 25
      Width = 264
      Height = 531
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      OnClick = lstFichiersClick
      OnDblClick = lstFichiersClick
    end
  end
  object splVertical: TSplitter
    Left = 280
    Top = 41
    Width = 5
    Height = 556
    Align = alLeft
  end
  object pnlClient: TPanel
    Left = 285
    Top = 41
    Width = 695
    Height = 556
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object pnlBoutons: TPanel
      Left = 0
      Top = 523
      Width = 695
      Height = 33
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      object btnExporter: TButton
        Left = 8
        Top = 4
        Width = 150
        Height = 25
        Caption = 'Exporter la selection...'
        TabOrder = 0
        OnClick = btnExporterClick
      end
      object btnExporterTout: TButton
        Left = 166
        Top = 4
        Width = 170
        Height = 25
        Caption = 'Exporter tous les fichiers...'
        TabOrder = 1
        OnClick = btnExporterToutClick
      end
    end
    object pgc: TPageControl
      Left = 0
      Top = 0
      Width = 695
      Height = 523
      ActivePage = tsArbo
      Align = alClient
      TabOrder = 1
      object tsArbo: TTabSheet
        Caption = 'Structure du message'
        object tvMessage: TTreeView
          Left = 0
          Top = 0
          Width = 695
          Height = 496
          Align = alClient
          Indent = 19
          ReadOnly = True
          TabOrder = 0
        end
      end
      object tsDonnees: TTabSheet
        Caption = 'Donnees extraites'
        object memoDonnees: TMemo
          Left = 0
          Top = 0
          Width = 695
          Height = 496
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Consolas'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssBoth
          TabOrder = 0
          WantReturns = False
        end
      end
    end
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 597
    Width = 980
    Height = 23
    SimplePanel = True
  end
  object tmrSurveillance: TTimer
    Interval = 2000
    OnTimer = tmrSurveillanceTimer
    Left = 920
    Top = 8
  end
  object dlgOuvrirDossier: TFileOpenDialog
    Options = [fdoPickFolders]
    Title = 'Choisir le dossier des fichiers HL7'
    Left = 440
    Top = 8
  end
  object dlgSauver: TSaveDialog
    DefaultExt = 'csv'
    Filter = 'Fichiers CSV (*.csv)|*.csv|Tous les fichiers (*.*)|*.*'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Exporter les donnees extraites'
    Left = 500
    Top = 8
  end
end
