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
    L_speed: TLabel;
    L_x: TLabel;
    OnApp: TApplicationProperties;
    OpenGLControl1: TOpenGLControl;
    RG_size: TRadioGroup;
    RG_color: TRadioGroup;
    RG_transp: TRadioGroup;
    RG_shape: TRadioGroup;
    RG_lifespan: TRadioGroup;
    TB_FogColor2: TTrackBar;
    TB_FogColor0: TTrackBar;
    TB_FogColor3: TTrackBar;
    TB_FogColor1: TTrackBar;
    TB_x: TTrackBar;
    TB_speed: TTrackBar;
    TB_y: TTrackBar;
    TB_amount: TTrackBar;
    TB_Density: TTrackBar;
    TB_FogStart: TTrackBar;
    TB_FogEnd: TTrackBar;
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
    FX,FY,FZ: Double;
    FXSpeed: Double;
    FYSpeed: Double;
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
    property XSpeed: Double read FXSpeed;
    property YSpeed: Double read FYSpeed;
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
    procedure Reset(RX,RY,RSpeed: double; RSize: integer; RColor: Array of Real; RTransp: Real; RShape,RLifespan: integer);
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
  SSpeed: Real;
  Amount: integer;
  SSize: integer;
  SColor: array[0..2] of Real;
  STransp: Real;
  SShape: integer;
  SLifespan: integer;

  ParticleArray: Array [0..1]of TParticle;
  P: TParticle;

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
       glPointSize(FSize);
       glColor4f(FColor[0],FColor[1],FColor[2],FTransp);
       glBegin(gl_Points);
         glVertex3f(FX, FY, FZ);
       glEnd
     end;
  1: begin
       glBegin(GL_QUADS);
         //glColor3f(0.0,0.0,1.0);    // Blau   Füllfarbe
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
  end;

end;

procedure TParticle.Move();
begin
  FXSpeed:= random(100);
  //FYSpeed:= random(200)-100;
  FX:= FX + FXSpeed/5000;
  FY:= FY + FYSpeed/500;
end;

procedure TParticle.Reset(RX,RY,RSpeed: Double; RSize: Integer; RColor: Array of Real; RTransp: Real; RShape,RLifespan: integer);
var AddY,AddX: Integer;
begin
  if Fage >= Flifespan then
    begin
      addx:= random(40)-20;
      addy:= random(40)-20;
      Fx:= rx + addx/100;
      Fy:= ry + addy/100;
      Fyspeed:= rspeed;
      Fsize:= rsize;
      Fcolor[0]:= rcolor[0];
      Fcolor[1]:= rcolor[1];
      Fcolor[2]:= rcolor[2];
      Ftransp:= rtransp;
      Fshape:= rshape;
      Flifespan:= rlifespan;
      Fage:= random(rlifespan);
    end;
end;
procedure TParticle.aging();
begin
  inc(Fage);
end;

{ TForm_Nebel }

procedure TForm_Nebel.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Application.AddOnIdlehandler(@OnAppIdle);
  Randomize;
  for i:= 0 to 100 do
    begin
      ParticleArray[i]:= TParticle.create();
    end;

  for i:= 0 to 7 do
    begin
      q:= gluNewQuadric();
      quadrics[i]:= q;
    end;
end;

procedure TForm_Nebel.OnAppIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=False;
  OpenGLControl1.Invalidate;
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


    //Textur
    Tex : PSDL_Surface;       // Texturbezeichnung
    TexID : gluInt;
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
  glEnable(gl_Blend);

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
    fogColor[1]:= TB_fogColor0.position/10;
    fogColor[2]:= TB_fogColor0.position/10;
    fogColor[3]:= TB_fogColor0.position/10;

    glEnable(GL_FOG);

    fogDensity:= TB_Density.position/10;
    fogStart:= TB_FogStart.position/10;
    fogEnd:= TB_FogEnd.position;

    fogMode:= GL_EXP;
        glFogi (GL_FOG_MODE, fogMode);
        glFogfv (GL_FOG_COLOR, fogColor);
        glFogf (GL_FOG_DENSITY, fogDensity);
        glHint (GL_FOG_HINT, GL_DONT_CARE);
        glFogf (GL_FOG_START, fogStart);
        glFogf (GL_FOG_END, fogEnd);
    glClearColor(0.5, 0.5, 0.5, 1.0);

    //Quardic erstellen
    Quadric := gluNewQuadric();

    //Eigenschaften der Quadrics einstellen
    gluQuadricOrientation(Quadric, GLU_OUTSIDE);
    gluQuadricDrawStyle(Quadric, GLU_FILL);
    gluQuadricNormals(Quadric, GLU_FLAT);
    gluQuadricTexture(Quadric, GL_TRUE);

    glShadeModel(GL_FLAT);


    //Quadrics zeichnen
    glcolor3f(1,0,0);

    i:= 0;
     while i < 7 do
       begin
        glpushmatrix();
        gltranslatef(0.4+i*-0.3,0,0.5+i*-0.7);
        glrotatef(90, 1,0,0);
        glrotatef(30, 0,0,1);
        glu.gluCylinder(quadrics[i], 0.1, 0.1, 0.2, 4, 50);
        glpopmatrix();
        inc(i);
       end;


  glPopMatrix();

  // Viewport rechts: Partikelsystem
  glViewport(Breite DIV 2,0,Breite,Hoehe);

  glPushMatrix();
    glLoadIdentity();
    // --- Kameraposition festlegen
    gluLookAt(0,0,1,0,0,0,0,1,0);
    // --- Transformation des Objekts

    // --- Polygonmodus einstellen
    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);

    //Textur laden
    Tex := IMG_Load('textur/Textur2.png');   //Dateipfad
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
      glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE); // GL_MODULATE (kein Ersetzen)
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

    // --- Objekt erzeugen

    case TB_amount.position of
  0:amount:= 0;
  1:amount:= 10;
  2:amount:= 20;
  3:amount:= 30;
  4:amount:= 40;
  5:amount:= 50;
  6:amount:= 60;
  7:amount:= 70;
  8:amount:= 90;
  9:amount:= 90;
  10:amount:= 100;
  end;

  case TB_x.position of
  0:Originx:= -1;
  1:Originx:= -0.8;
  2:Originx:= -0.6;
  3:Originx:= -0.4;
  4:Originx:= -0.2;
  5:Originx:= 0;
  6:Originx:= 0.2;
  7:Originx:= 0.4;
  8:Originx:= 0.6;
  9:Originx:= 0.8;
  10:Originx:= 1;
  end;
  case TB_y.position of
  0:Originy:= -1;
  1:Originy:= -0.8;
  2:Originy:= -0.6;
  3:Originy:= -0.4;
  4:Originy:= -0.2;
  5:Originy:= 0;
  6:Originy:= 0.2;
  7:Originy:= 0.4;
  8:Originy:= 0.6;
  9:Originy:= 0.8;
  10:Originy:= 1;
  end;
  case TB_speed.position of
  0:sspeed:= -100;
  1:sspeed:= -80;
  2:sspeed:= -60;
  3:sspeed:= -40;
  4:sspeed:= -20;
  5:sspeed:= 0;
  6:sspeed:= 20;
  7:sspeed:= 40;
  8:sspeed:= 60;
  9:sspeed:= 80;
  10:sspeed:= 100;
  end;

  case RG_size.itemindex of
  0:ssize:= 3;
  1:ssize:= 5;
  2:ssize:= 10;
  end;

  case RG_color.itemindex of
  0:begin
    scolor[0]:= 0.5;
    scolor[1]:= 0.5;
    scolor[2]:= 0.5;
    end;

  1:begin
    scolor[0]:= 1;
    scolor[1]:= 1;
    scolor[2]:= 1;
    end;

  2:begin
    scolor[0]:= 0;
    scolor[1]:= 0;
    scolor[2]:= 1;
    end;
  end;

  case RG_transp.itemindex of
  0:stransp:= 0.1;
  1:stransp:= 0.5;
  2:stransp:= 0.8;
  end;

  case RG_shape.itemindex of
  0:sshape:= 0;
  1:sshape:= 1;
  end;

  case RG_lifespan.itemindex of
  0:slifespan:= 30;
  1:slifespan:= 500;
  2:slifespan:= 1000;
  end;

  for i:= 0 to 100 do
    begin
      ParticleArray[i].reset(Originx,Originy,sspeed,ssize,scolor,stransp,sshape,slifespan);
      ParticleArray[i].show;
      ParticleArray[i].move;
      ParticleArray[i].aging;
    end;
  glPopMatrix();

  //Quadrics löschen
  gluDeleteQuadric(Quadric);

  // Textur löschen
  glDisable(GL_TEXTURE_2D);      //um Objekte zu zeichnen ohne Textur
  glDeleteTextures(1,@TexID);    // Freigabe der Textur

  // Zeichnen
  glFlush();

  // Bildschirmausgabe aktualisieren
  OpenGLControl1.SwapBuffers;



end;

procedure TForm_Nebel.OpenGLControl1Resize(Sender: TObject);
begin
  IF OpenGLControl1.Height <= 0 THEN Exit;
end;

end.

