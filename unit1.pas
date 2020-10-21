unit Unit1;
{$mode objfpc}{$H+}

{Autor: Felix Heinrich}

interface

uses
  Classes, SysUtils, FileUtil, OpenGLContext, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ComCtrls, GLU, GL, ExtCtrls, SDL, SDL_Image;

type

  { TForm_Nebel }

  TForm_Nebel = class(TForm)
    L_Density: TLabel;
    L_FogColor0: TLabel;
    L_FogColor2: TLabel;
    L_FogColor3: TLabel;
    L_FogStart: TLabel;
    L_FogEnd: TLabel;
    L_amount: TLabel;
    L_FogColor1: TLabel;
    L_y: TLabel;
    L_Yspeed: TLabel;
    L_x: TLabel;
    OnApp: TApplicationProperties;
    OpenGLControl1: TOpenGLControl;
    OpenGLControl2: TOpenGLControl;
    P_V: TPanel;
    P_H: TPanel;
    RG_FogMode: TRadioGroup;
    RG_size: TRadioGroup;
    RG_color: TRadioGroup;
    RG_transp: TRadioGroup;
    RG_shape: TRadioGroup;
    RG_lifespan: TRadioGroup;
    TB_Emitter: TTrackBar;
    TB_FogColor2: TTrackBar;
    TB_FogColor0: TTrackBar;
    TB_FogColor3: TTrackBar;
    TB_FogColor1: TTrackBar;
    TB_x: TTrackBar;
    TB_Yspeed: TTrackBar;
    TB_y: TTrackBar;
    TB_Density: TTrackBar;
    TB_FogStart: TTrackBar;
    TB_FogEnd: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure OnAppIdle(Sender: TObject; var Done: Boolean);
    procedure OpenGLControl1Click(Sender: TObject);
    procedure OpenGLControl1Paint(Sender: TObject);
    procedure OpenGLControl1Resize(Sender: TObject);
    procedure P_VClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  { TParticle }
  TParticle = class
  private
    FX,FY,FZ: Double;
    FXSpeed: integer;
    FYSpeed: integer;
    FSize: integer;
    FColor: Array[0..2] of Real;
    FTransp: Real;
    FShape: integer;
    FLifespan: integer;
    FAge: integer;

  public
    constructor Create;

    property X: Double read FX;
    property Y: Double read FY;
    property Z: Double read FZ;
    property XSpeed: integer read FXSpeed;
    property YSpeed: integer read FYSpeed;
    property Size: integer write FSize;
    property Color1: Real write FColor[1];
    property Color2: Real write FColor[2];
    property Color3: Real write FColor[3];
    property Transp: Real write FTransp;
    property Shape: integer write FShape;
    property Lifespan: integer write FLifespan;
    property Age: integer read Fage write FAge;

    procedure Show();
    procedure Move();
    procedure Reset(RX,RY: Double;RSpeed: integer; RSize: Integer; RColor: Array of Real; RTransp: Real; RShape,RLifespan,REmitter: integer);
    procedure Aging();
  end;

var
  //TFrom1
  Form_Nebel: TForm_Nebel;

  //Fogging
  Quadrics: Array[0..7] of PGLuquadric;
  Q:PGLuquadric;

  //Partikelsystem
  OriginX: double;
  OriginY: double;
  OriginZ: double = 0;
  SSpeed: integer;
  Amount: integer = 300;
  SSize: integer;
  SColor: array[0..2] of Real;
  STransp: Real;
  SShape: integer;
  SLifespan: integer;
  SEmitter: integer;

  ParticleArray: Array of TParticle;
  P: TParticle;

  //Textur
  Tex : PSDL_Surface;
  TexID : gluInt;

  //Kreispartikel
  PQuadric: PGLuquadric;

implementation

{$R *.lfm}

{ TParticle }

constructor TParticle.Create();
begin
 FAge:= random(100);
end;


procedure TParticle.Show();
var
  TSize:Double;
begin
  TSize:= FSize/200;

  case FShape of
  0: begin
       glDisable(GL_TEXTURE_2D);      //Textur deaktivieren
       glPointSize(FSize);
       glColor4f(FColor[0],FColor[1],FColor[2],FTransp);
       glBegin(gl_Points);
         glVertex3f(FX, FY, FZ);
       glEnd
     end;
  1: begin
       glBegin(GL_QUADS);
         glTexCoord2f(0,1);	         // Texturpunkt für A
         glVertex3f(FX-TSize,FY-TSize,0);     // Quadratpunkt A
         glTexCoord2f(1,1);           // Texturpunkt für B
         glVertex3f(FX+TSize,FY-TSize,0);     // Quadratpunkt B
         glTexCoord2f(1,0);           // Texturpunkt für C
         glVertex3f(FX+TSize,FY+TSize,0);     // Quadratpunkt C
         glTexCoord2f(0,0);           // Texturpunkt für D
         glVertex3f(FX-TSize,FY+TSize,0);     // Quadratpunkt D
         glEnd();
     end;
  2: begin
       glpushmatrix();
         gltranslatef(FX,FY,0);
         glrotatef(90, 0,0,1);
         glu.gluDisk(PQuadric, 0, FSize/100, 50, 50);
       glpopmatrix();
     end;

  end;

end;

procedure TParticle.Move();
begin
  FX:= FX + FXSpeed/5000;
  FY:= FY + (random(FYSpeed)-FYSpeed/2)/5000;
end;

procedure TParticle.Reset(RX,RY: Double;RSpeed: integer; RSize: Integer; RColor: Array of Real; RTransp: Real; RShape,RLifespan,REmitter: integer);
var
  AddX, AddY: Real;
begin
  AddX:= random(REmitter)-REmitter/2;
  AddY:= random(REmitter)-REmitter/2;
  if Fage >= Flifespan then
    begin
      FX:= rx + AddX/100;
      FY:= ry + AddY/100;
      FYspeed:= RSpeed;
      FXSpeed:= random(80)+10;
      FSize:= RSize;
      FColor:= RColor;
      FTransp:= RTransp;
      FShape:= RShape;
      FLifespan:= RLifespan;
      FAge:= random(RLifespan);
    end;
end;
procedure TParticle.aging();
begin
  inc(FAge);
end;

{ TForm_Nebel }

procedure TForm_Nebel.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Application.AddOnIdlehandler(@OnAppIdle);
  Randomize;

  setlength(ParticleArray,amount);
  for i:= 0 to length(ParticleArray) do
    begin
      ParticleArray[i]:= TParticle.create();
    end;

  for i:= 0 to 7 do
    begin
      q:= gluNewQuadric();
      quadrics[i]:= q;
    end;

  PQuadric:= gluNewQuadric();
    gluQuadricOrientation(PQuadric, GLU_OUTSIDE);  //Default: false
    gluQuadricDrawStyle(PQuadric, GLU_FILL);      //Default: GLU_FILL
    gluQuadricNormals(PQuadric, GLU_FLAT);     //Default: GLU_SMOOTH
    gluQuadricTexture(PQuadric, GL_TRUE);      //Default: GLU_OUTSIDE

end;

procedure TForm_Nebel.OnAppIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=False;
  OpenGLControl1.Invalidate;
end;

procedure TForm_Nebel.OpenGLControl1Click(Sender: TObject);
begin

end;


procedure TForm_Nebel.OpenGLControl1Paint(Sender: TObject);
Var Breite,Hoehe: integer;
    i: integer; //Zählvariable

    //Quader für Fogging
    Quadric : PGLuquadric;

    Lichtposition : Array[0..3] of glFloat;

    //Nebel
    fogColor: Array[0..3] of glFloat;
    fogMode: glint;
    fogDensity: Real;
    fogStart: Real;
    FogEnd: Real;

CONST
    Links:Real = -1.0;     // Left
    Rechts:Real = 1.0;     // Right
    Unten:Real = -1.0;     // Bottom
    Oben:Real = 1.0;       // Top
    Vorne:Real = 0.1;       // Teleeffekt Near        (muss positiv sein)
    Hinten:Real = 10.0;    // Weitwinkeleffekt Far   (muss positiv sein)

 begin
  //Darstellungsfenster und Tiefenpuffer definieren
  Breite:= Openglcontrol1.width;
  hoehe:= openglcontrol1.height;
  glviewport(0,0,Breite,Hoehe);
  glClearColor(0,0,0,0);
  glClear(GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT);

  //Norlmalenbezug und Normalenberechnung
  glenable(gl_normalize);

  //Projektionsmatrix laden
  glmatrixmode(gl_projection);
  glloadidentity();

  //Blending aktivieren
  glEnable(GL_BLEND);

  // Einteilung des Viewports (Darstellung der Linien)
  glBegin(GL_LINES);
    // Farbe der Linie
    glColor4f(1,1,1,0); // weiß
    // Vertikale Linie
    glVertex2f(0,-1);
    glVertex2f(0,1);
  glEnd;


  //Festlegung der Projektion
  gluperspective(45,(Breite/Hoehe),0.1,100);


  //Transformation der Projektionsmatrix


  //Modellmatrix laden
  glmatrixmode(gl_modelview);
  glloadidentity();

  //Lichteinstellungen
  Lichtposition[0]:=0.0;      // X-Achse  -1.0
  Lichtposition[1]:=0.0;       // Y-Achse
  Lichtposition[2]:=1.0;       // Z-Achse   Kameraposition
  Lichtposition[3]:=1.0;       // 1.0=feste Position | 0.0=freie Position

  glLightfv(GL_LIGHT0,        // Lichtquelle
            GL_POSITION,      // Leutposition
            Lichtposition);   // Lichtquellenkoordinaten

  // Viewport links: Fogging
  glViewport(0,0,Breite DIV 2,Hoehe);
  glPushMatrix();
    glLoadIdentity();

    // --- Kameraposition festlegen
    gluLookAt(0,0,2,0,0,0,0,-1,0);

    //Tiefenpuffer aktivieren
    glEnable(GL_Depth_TEST);

    // --- Polygonmodus einstellen
    glPolygonMode(GL_FRONT_AND_BACK,gl_fill);

    // Licht
    glEnable(GL_COLOR_MATERIAL);
    glEnable(GL_LIGHT0);
    glEnable(GL_LIGHTING);
    glColorMaterial(GL_FRONT, GL_AMBIENT_AND_DIFFUSE);

    //Nebel
    fogColor[0]:= TB_fogColor0.position/10;
    fogColor[1]:= TB_fogColor1.position/10;
    fogColor[2]:= TB_fogColor2.position/10;
    fogColor[3]:= TB_fogColor3.position/5;

    //Hintergrund in Farbe des Nebels
    glClearColor(fogColor[0],fogColor[1],fogColor[2],fogColor[3]);
    glClear(GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT);

    glEnable(GL_FOG);

    fogDensity:= TB_Density.position/10;
    fogStart:= (TB_FogStart.position-10);
    fogEnd:= TB_FogEnd.position;

    case RG_FogMode.itemindex of
    0:fogMode:= GL_EXP;
    1:fogMode:= GL_EXP2;
    2:fogMode:= GL_LINEAR;
    end;

        glFogi (GL_FOG_MODE, fogMode);
        glFogfv (GL_FOG_COLOR, fogColor);
        glFogf (GL_FOG_DENSITY, fogDensity);
        glHint (GL_FOG_HINT, GL_DONT_CARE);
        glFogf (GL_FOG_START, fogStart);
        glFogf (GL_FOG_END, fogEnd);
    glClearColor(fogColor[0], fogColor[1], fogColor[2], fogColor[3]);

    //Quardic erstellen
    Quadric := gluNewQuadric();

    //Eigenschaften der Quadrics einstellen
    gluQuadricOrientation(Quadric, GLU_OUTSIDE);
    gluQuadricDrawStyle(Quadric, GLU_FILL);
    gluQuadricNormals(Quadric, GLU_FLAT);
    gluQuadricTexture(Quadric, GL_TRUE);
    glShadeModel(GL_FLAT);


    //Quadrics zeichnen
    glColor3f(1,0,0);
     for i:= 0 to 7 do
       begin
        glpushmatrix();
        gltranslatef(0.4+i*-0.3,0.1,0.5+i*-0.7);
        glrotatef(90, 1,0,0);
        glrotatef(30, 0,0,1);
        glu.gluCylinder(quadrics[i], 0.1, 0.1, 0.2, 4, 50);
        glpopmatrix();
       end;

  glPopMatrix();
  glDisable(GL_FOG);

  // Viewport rechts: Partikelsystem
  glViewport(Breite DIV 2,0,Breite,Hoehe);

  // Hintergrund schwarz
  glbegin(GL_Quads);
    glcolor3f(0,0,0);
    glvertex3f(-20,-20,-20);
    glvertex3f(20,-20,-20);
    glvertex3f(20,20,-20);
    glvertex3f(-20,20,-20);
  glend;

  glPushMatrix();
    glLoadIdentity();
    // --- Kameraposition festlegen
    gluLookAt(0,0,1,0,0,0,0,1,0);
    // --- Transformation des Objekts

    // --- Polygonmodus einstellen
    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);

    // Licht
    glDisable(GL_COLOR_MATERIAL);
    glDisable(GL_LIGHT0);
    glDisable(GL_LIGHTING);

    //Textur laden
    Tex:= IMG_Load('textur/Textur6.png');

    IF assigned(Tex) THEN
      BEGIN
        // eindeutige Kennung für die Textur generieren
        glGenTextures(1, @TexID);
        // Textur einbinden (Rendern der Textur)
        glBindTexture( GL_TEXTURE_2D, TexID);
        // Definition, wie die Textur beim Mipmapping gefiltert werden soll
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        // Texturfarben sollen ursprüngliche Farben ersetzen
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // kein Ersetzen der Farben  (sonst GL_REPLACE)
        // Art der Abbildung der Textur
        // generiert aus einer Textur alle Mipmap-Stufen
        // gluBuild2DMipmaps(GL_TEXTURE_2D,GL_RGB,Tex^.W,Tex^.H,GL_RGB,GL_UNSIGNED_BYTE,PByte(Tex^.Pixels));
        // spezifiziert ein zweidimensionales Texturbild
        glTexImage2D(GL_TEXTURE_2D,0,3,Tex^.W,Tex^.H,0,GL_RGB,GL_UNSIGNED_BYTE,Tex^.Pixels);
        // Gibt die Texturkennung frei
        SDL_FreeSurface(Tex);
      END;


  // Aktivierung einer zweidimensionalen Textur
  glEnable(GL_TEXTURE_2D);

  //Objekt erzeugen

    case TB_Emitter.position of
  0:SEmitter:= 0;
  1:SEmitter:= 10;
  2:SEmitter:= 20;
  3:SEmitter:= 30;
  4:SEmitter:= 40;
  5:SEmitter:= 50;
  6:SEmitter:= 60;
  7:SEmitter:= 70;
  8:SEmitter:= 90;
  9:SEmitter:= 90;
  10:SEmitter:= 100;
  end;

  case TB_x.position of
  0:Originx:= -1;
  1:Originx:= -0.9;
  2:Originx:= -0.8;
  3:Originx:= -0.7;
  4:Originx:= -0.6;
  5:Originx:= -0.5;
  6:Originx:= -0.4;
  7:Originx:= -0.3;
  8:Originx:= -0.2;
  9:Originx:= -0.1;
  10:Originx:= 0;
  end;
  case TB_y.position of
  0:Originy:= -0.4;
  1:Originy:= -0.3;
  2:Originy:= -0.2;
  3:Originy:= -0.1;
  4:Originy:= -0.05;
  5:Originy:= 0;
  6:Originy:= 0.05;
  7:Originy:= 0.1;
  8:Originy:= 0.2;
  9:Originy:= 0.3;
  10:Originy:= 0.4;
  end;
  case TB_Yspeed.position of
  0:SSpeed:= 0;
  1:SSpeed:= 5;
  2:SSpeed:= 10;
  3:SSpeed:= 15;
  4:SSpeed:= 20;
  5:SSpeed:= 25;
  6:SSpeed:= 30;
  7:SSpeed:= 35;
  8:SSpeed:= 40;
  9:SSpeed:= 45;
  10:SSpeed:= 50;
  end;

  case RG_size.itemindex of
  0:ssize:= 3;
  1:ssize:= 5;
  2:ssize:= 10;
  end;

  case RG_color.itemindex of
  0:begin
    SColor[0]:= 0.5;
    SColor[1]:= 0.5;
    SColor[2]:= 0.5;
    end;

  1:begin
    SColor[0]:= 1;
    SColor[1]:= 1;
    SColor[2]:= 1;
    end;

  2:begin
    SColor[0]:= 0;
    SColor[1]:= 0;
    SColor[2]:= 1;
    end;
  end;

  case RG_transp.itemindex of
  0:STransp:= 0.1;
  1:STransp:= 0.5;
  2:STransp:= 0.8;
  end;

  case RG_shape.itemindex of
  0:SShape:= 0;
  1:SShape:= 1;
  2:SShape:= 2;
  end;

  case RG_lifespan.itemindex of
  0:SLifespan:= 30;
  1:SLifespan:= 500;
  end;

  for i:= 0 to length(ParticleArray) do
    begin
      ParticleArray[i].reset(OriginX,OriginY,SSpeed,SSize,SColor,STransp,SShape,SLifespan,SEmitter);
      ParticleArray[i].show;
      ParticleArray[i].move;
      ParticleArray[i].aging;
    end;
  glPopMatrix();

  //Quadrics löschen
  gluDeleteQuadric(Quadric);

  // Textur löschen
  glDisable(GL_TEXTURE_2D);      //Textur deaktivieren
  glDeleteTextures(1,@TexID);    // Löschen der Textur


  // Zeichnen
  glFlush();

  // Bildschirmausgabe aktualisieren
  OpenGLControl1.SwapBuffers;

end;

procedure TForm_Nebel.OpenGLControl1Resize(Sender: TObject);
begin
  IF OpenGLControl1.Height <= 0 THEN Exit;
end;

procedure TForm_Nebel.P_VClick(Sender: TObject);
begin

end;

end.

