program HL7Transfert;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {FormMain},
  uHL7 in 'uHL7.pas',
  uHL7Extract in 'uHL7Extract.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
