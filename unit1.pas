unit Unit1;
{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, OpenGLContext, Forms, Controls, Graphics,
  Dialogs, GLU, GL;

type

  { TForm1 }

  TForm1 = class(TForm)
    OnApp: TApplicationProperties;
    OpenGLControl1: TOpenGLControl;
    procedure FormCreate(Sender: TObject);
    procedure OnAppIdle(Sender: TObject; var Done: Boolean);
    procedure OpenGLControl1Paint(Sender: TObject);
    procedure OpenGLControl1Resize(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  { TParticle }
  TParticle = class
  private
    FX: Double;
    FY: Double;
    FZ: Double;
    FSpeed: Real;
    procedure SetSpeed(speed: Real);
  public
    constructor Create(x, y, z: Double; speed: Real = 0.01);
    property x: Double read FX;
    property y: Double read FY;
    property z: Double read FZ;
    property speed: Real read FSpeed write SetSpeed;

    procedure show();
    procedure move();
  end;


var
  Form1: TForm1;
  p: TParticle;


implementation

{$R *.lfm}

{ TParticle }

constructor TParticle.Create(x, y, z: Double; speed: Real = 0.01);
begin
  FX:= x;
  FY:= y;
  FZ:= z;
  FSpeed:= speed;
end;

procedure TParticle.SetSpeed(speed: Real);
begin
  FSpeed:= speed;
end;

procedure TParticle.show();
begin
  glcolor4f(1,1,1,1);
  glBegin(gl_points);
    glVertex3f(FX, FY, FZ);
  glEnd;
end;

procedure TParticle.move();
begin
  FX:= FX + FSpeed;
  FY:= FY + FSpeed;
  // FZ:= FZ + FSpeed;
end;

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  Application.AddOnIdlehandler(@OnAppIdle);
  p:= TParticle.Create(0,0,0);
end;

procedure TForm1.OnAppIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=False;
  OpenGLControl1.Invalidate;
end;

procedure TForm1.OpenGLControl1Paint(Sender: TObject);
Var Breite,Hoehe: integer;

 begin
  Breite:= Openglcontrol1.width;
  hoehe:= openglcontrol1.height;

  //Darstellungsfenster und Tiefenpuffer definieren
  glviewport(0,0,Breite,Hoehe);
  glClearColor(0,0,0,0);
  glClear(GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT);

  //Norlmalenbezug und Normalenberechnung
  glenable(gl_normalize);

  //Projektionsmatrix laden
  glmatrixmode(gl_projection);
  glloadidentity();

  //Festlegung der Projektion
  gluperspective(45,(Breite/Hoehe),0.1,100);

  //Transformation der Projektionsmatrix


  //Modellmatrix laden
  glmatrixmode(gl_modelview);
  glloadidentity();

  //Tiefenpuffer aktivieren
  glEnable(GL_DEPTH_TEST);

  //Kameraposition festlegen
  glulookat(0,0,5,0,0,0,0,1,0);

  //Objekttransformation

  //Textur laden

  //Objekt erzeugen
  p.show();
  p.move();

  //Beeinflussung der Transformation

  // Zeichnen
  glFlush();

  // Bildschirmausgabe aktualisieren
  OpenGLControl1.SwapBuffers;

  Sleep(50);

end;

procedure TForm1.OpenGLControl1Resize(Sender: TObject);
begin
  IF OpenGLControl1.Height <= 0 THEN Exit;
end;

end.

