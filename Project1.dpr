program Project1;

uses
  Vcl.Forms,
  UFrmGitUpdate in 'UFrmGitUpdate.pas' {FrmGitUpdate};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmGitUpdate, FrmGitUpdate);
  Application.Run;
end.
