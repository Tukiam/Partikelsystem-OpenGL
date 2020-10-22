unit Unit1;
{$mode objfpc}{$H+}

{Autor: Felix Heinrich}

interface

uses
  Classes, SysUtils, FileUtil, OpenGLContext, Forms, Controls, Graphics,
  Dialogs, StdCtrls, ComCtrls, GLU, GL, ExtCtrls, SDL, SDL_Image;

type

  { TF_Nebel }

  TF_Nebel = class(TForm)
    L_Density: TLabel;
    L_FogColor0: TLabel;
    L_FogColor2: TLabel;
    L_FogColor3: TLabel;
    L_FogStart: TLabel;
    L_FogEnd: TLabel;
    L_Emitter: TLabel;
    L_FogColor1: TLabel;
    L_EmitterY: TLabel;
    L_Yspeed: TLabel;
    L_EmitterX: TLabel;
    OnApp: TApplicationProperties;
    OpenGLControl1: TOpenGLControl;
    OpenGLControl2: TOpenGLControl;
    P_Vertical: TPanel;
    P_Horizontal: TPanel;
    RG_FogMode: TRadioGroup;
    RG_Size: TRadioGroup;
    RG_Color: TRadioGroup;
    RG_Transp: TRadioGroup;
    RG_Shape: TRadioGroup;
    RG_Lifespan: TRadioGroup;
    TB_Emitter: TTrackBar;
    TB_FogColor2: TTrackBar;
    TB_FogColor0: TTrackBar;
    TB_FogColor3: TTrackBar;
    TB_FogColor1: TTrackBar;
    TB_EmitterX: TTrackBar;
    TB_Yspeed: TTrackBar;
    TB_EmitterY: TTrackBar;
    TB_Density: TTrackBar;
    TB_FogStart: TTrackBar;
    TB_FogEnd: TTrackBar;
    procedure FormCreate(Sender: TObject);
    procedure OnAppIdle(Sender: TObject; var Done: Boolean);
    procedure OpenGLControl1Paint(Sender: TObject);
    procedure OpenGLControl1Resize(Sender: TObject);
    procedure P_VerticalClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

  { TParticle }
  TParticle = class
  private
    FX,FY,FZ: Double;
    FXSpeed: Real;
    FYSpeed: Real;
    FSize: integer;
    FColor: Array[0..2] of Real;
    FTransp: Real;
    FShape: integer;
    FLifespan: integer;
    FAge: integer;

  public
    constructor Create;

    procedure Show();
    procedure Move();
    procedure Reset();
    procedure Aging();
  end;

var
  //Formular
  F_Nebel: TF_Nebel;

  //Fogging
  Quadrics: Array[0..7] of PGLuquadric;

  //Partikelsystem
    //Eigenschaften
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

    //PartikelArray
  ParticleArray: Array of TParticle;

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
 FAge:= random(100); //zufälliges Alter
end;

procedure TParticle.Show();               //Prozedur für das Anzeigen der Partikel
var
  QSize:Double;
  CSize:Double;
begin
  QSize:= FSize/200;                      //Partikelgröße für Quadrate anpassen
  CSize:= FSize/100;                      //Partikelgröße für Kreispartikel anpassen

  case FShape of
  0: begin
       glDisable(GL_TEXTURE_2D);          //Textur deaktivieren
       glPointSize(FSize);                                 //Punktgröße
       glColor4f(FColor[0],FColor[1],FColor[2],FTransp);   //Punktfarbe
       glBegin(gl_Points);
         glVertex3f(FX, FY, FZ);          //Punkt zeichnen
       glEnd
     end;
  1: begin
       glBegin(GL_QUADS);
         glTexCoord2f(0,1);	           // Texturpunkt für A
         glVertex3f(FX-QSize,FY-QSize,0);  // Quadratpunkt A - links unten
         glTexCoord2f(1,1);                // Texturpunkt für B
         glVertex3f(FX+QSize,FY-QSize,0);  // Quadratpunkt B - rechts unten
         glTexCoord2f(1,0);                // Texturpunkt für C
         glVertex3f(FX+QSize,FY+QSize,0);  // Quadratpunkt C - rechts oben
         glTexCoord2f(0,0);                // Texturpunkt für D
         glVertex3f(FX-QSize,FY+QSize,0);  // Quadratpunkt D - links oben
         glEnd();
     end;
  2: begin
       gluQuadricOrientation(PQuadric, GLU_OUTSIDE);  //Default: false
       gluQuadricDrawStyle(PQuadric, GLU_FILL);      //Default: GLU_FILL
       gluQuadricNormals(PQuadric, GLU_FLAT);     //Default: GLU_SMOOTH
       gluQuadricTexture(PQuadric, GL_TRUE);      //Default: GLU_OUTSIDE
       glpushmatrix();                     //neue Matrix auf den Stapel
         gltranslatef(FX,FY,0);            //Objekttransformation
         glrotatef(90, 0,0,1);             //Objektrotation
         glu.gluDisk(PQuadric, 0, CSize, 50, 50);  //Objekt zeichnen
       glpopmatrix();                      //Matrix vom Stapel nehmen
     end;
  end;
end;

procedure TParticle.Move();                //Prozedur für die Bewegung der Partikel
begin
  FX:= FX + FXSpeed/5000;                  //Skalierung der Geschwindigkeit
  FY:= FY + FYSpeed/5000;
end;

procedure TParticle.Reset();               //Prozedur für das Zurücksetzen der Partikel
var                                        //nach Ablauf der Lebensdauer
  AddX, AddY: Real;
begin
  AddX:= random(SEmitter)-SEmitter/2;      //Variable für Emitterstreuung
  AddY:= random(SEmitter)-SEmitter/2;      //Variable für Emitterstreuung
  if Fage >= Flifespan then                //Ende der Lebensdauer des Partikels
    begin
      FX:= OriginX + AddX/100;             //Setzen der Position
      FY:= OriginY + AddY/100;
      FYspeed:= random(SSpeed)-SSpeed/2;   //Setzen der Geschwindigkeit
      FXSpeed:= random(80)+10;
      FSize:= SSize;                       //Partikeleigenschaften aus Komponenten entnehmen
      FColor:= SColor;
      FTransp:= STransp;
      FShape:= SShape;
      FLifespan:= SLifespan;
      FAge:= random(SLifespan);
    end;
end;
procedure TParticle.aging();               //Prozedur für das Altern der Partikel
begin
  inc(FAge);                               //Alter erhöhen
end;

{ TF_Nebel }

procedure TF_Nebel.FormCreate(Sender: TObject);
var
  i: integer;                              //Zählvariable
begin
  Application.AddOnIdlehandler(@OnAppIdle);
  Randomize;

  SetLength(ParticleArray,amount);         //Länge des Partikelarrays setzen
  for i:= 0 to length(ParticleArray) do    //Schleife durch das Partikelarray
    begin
      ParticleArray[i]:= TParticle.create();  //Partikelarray mit Partikeln füllen
    end;

  for i:= 0 to 7 do
    begin
      Quadrics[i]:= gluNewQuadric();;      //Quadrics für Fogging erstellen
    end;

  PQuadric:= gluNewQuadric();              //Kreispartikel erstellen
end;

procedure TF_Nebel.OnAppIdle(Sender: TObject; var Done: Boolean);
begin
  Done:=False;
  OpenGLControl1.Invalidate;
end;

procedure TF_Nebel.OpenGLControl1Paint(Sender: TObject);
Var Breite,Hoehe: integer;
    i: integer;                            //Zählvariable

    //Array für Lichtposition
    Lichtposition : Array[0..3] of glFloat;

    //Nebeleigenschaften
    fogColor: Array[0..3] of glFloat;
    fogMode: glint;
    fogDensity: Real;
    fogStart: Real;
    FogEnd: Real;

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
    glColor4f(1,1,1,0);                    // weiß
    // Vertikale Linie
    glVertex2f(0,-1);
    glVertex2f(0,1);
  glEnd;

  //Festlegung der Projektion
  gluperspective(45,(Breite/Hoehe),0.1,100);

  //Modellmatrix laden
  glmatrixmode(gl_modelview);
  glloadidentity();

  //Lichteinstellungen
  Lichtposition[0]:=0.0;                   //X-Achse
  Lichtposition[1]:=0.0;                   //Y-Achse
  Lichtposition[2]:=1.0;                   //Z-Achse   Kameraposition
  Lichtposition[3]:=1.0;                   //1.0=feste Position | 0.0=freie Position

  glLightfv(GL_LIGHT0,                     //Lichtquelle
            GL_POSITION,                   //Leutposition
            Lichtposition);                //Lichtquellenkoordinaten

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
    //Nebelfarbe aus Komponenten entnehmen
    fogColor[0]:= TB_fogColor0.position/10;
    fogColor[1]:= TB_fogColor1.position/10;
    fogColor[2]:= TB_fogColor2.position/10;
    fogColor[3]:= TB_fogColor3.position/5;

    //Hintergrund in Farbe des Nebels
    glClearColor(fogColor[0],fogColor[1],fogColor[2],fogColor[3]);
    glClear(GL_COLOR_BUFFER_BIT OR GL_DEPTH_BUFFER_BIT);

    //Nebel einschalten
    glEnable(GL_FOG);

    //Nebeleigenschaten aus Komponenten entnehmen
    fogDensity:= TB_Density.position/10;
    fogStart:= (TB_FogStart.position-10);
    fogEnd:= TB_FogEnd.position;

    case RG_FogMode.itemindex of
    0:fogMode:= GL_EXP;
    1:fogMode:= GL_EXP2;
    2:fogMode:= GL_LINEAR;
    end;

    //Nebel setzen und einschalten
        glFogi (GL_FOG_MODE, fogMode);
        glFogfv (GL_FOG_COLOR, fogColor);
        glFogf (GL_FOG_DENSITY, fogDensity);
        glHint (GL_FOG_HINT, GL_DONT_CARE);
        glFogf (GL_FOG_START, fogStart);
        glFogf (GL_FOG_END, fogEnd);
    glClearColor(fogColor[0], fogColor[1], fogColor[2], fogColor[3]);

    //Quadrics zeichnen
    glColor3f(1,0,0);                      //Rot
     for i:= 0 to 7 do
       begin
        glpushmatrix();
        //Eigenschaften der Quadrics einstellen
        gluQuadricOrientation(Quadrics[i], GLU_OUTSIDE);
        gluQuadricDrawStyle(Quadrics[i], GLU_FILL);
        gluQuadricNormals(Quadrics[i], GLU_FLAT);
        gluQuadricTexture(Quadrics[i], GL_TRUE);
        glShadeModel(GL_FLAT);

        gltranslatef(0.4+i*-0.3,0.1,0.5+i*-0.7);
        glrotatef(90, 1,0,0);
        glrotatef(30, 0,0,1);
        glu.gluCylinder(quadrics[i], 0.1, 0.1, 0.2, 4, 50);
        glpopmatrix();
       end;

  glPopMatrix();
  glDisable(GL_FOG);                       //Nebel deaktivieren

  // Viewport rechts: Partikelsystem
  glViewport(Breite DIV 2,0,Breite,Hoehe);

  // Hintergrundfarbe setzen
  glbegin(GL_Quads);                       //großes Quadrat als Hintergrund
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

    // --- Polygonmodus einstellen
    glPolygonMode(GL_FRONT_AND_BACK,GL_FILL);

    // Licht ausschalten
    glDisable(GL_COLOR_MATERIAL);
    glDisable(GL_LIGHT0);
    glDisable(GL_LIGHTING);

    //Textur laden
    Tex:= IMG_Load('textur/Textur6.png');

    //Textur setzen und einschalten
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
  //Wertentname aus den Komponenten
  SEmitter:= TB_Emitter.position*10;       //Emitterstreuung
  OriginX:= (-10+TB_EmitterX.position)/10;
  OriginY:= (-4+TB_EmitterY.position-0.1*TB_EmitterY.position)/10;
  SSpeed:= TB_Yspeed.position*5;           //y-Geschwindigkeit

  case RG_Size.itemindex of                //Partikelgröße
  0:SSize:= 3;
  1:SSize:= 5;
  2:SSize:= 10;
  end;

  case RG_Color.itemindex of               //Partikelfarbe
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

  case RG_Transp.itemindex of              //Partikeltransparenz
  0:STransp:= 0.1;
  1:STransp:= 0.5;
  2:STransp:= 0.8;
  end;

  SShape:= RG_Shape.itemindex;             //Partikelform

  case RG_Lifespan.itemindex of            //Lebensdauer des Partikels
  0:SLifespan:= 30;
  1:SLifespan:= 50;
  2:SLifespan:= 100;
  end;

  for i:= 0 to length(ParticleArray) do    //Schleife durch Partikelarray
    begin
      ParticleArray[i].reset();            //Zurücksetzen der Partikel
      ParticleArray[i].show;               //Anzeigen der Partikel
      ParticleArray[i].move;               //Bewegen der Partikel
      ParticleArray[i].aging;              //Altern der Partikel
    end;
  glPopMatrix();

  // Textur deaktivieren
  glDisable(GL_TEXTURE_2D);
  //Textur löschen
  glDeleteTextures(1,@TexID);

  // Zeichnen
  glFlush();

  // Bildschirmausgabe aktualisieren
  OpenGLControl1.SwapBuffers;

end;

procedure TF_Nebel.OpenGLControl1Resize(Sender: TObject);
begin
  IF OpenGLControl1.Height <= 0 THEN Exit;
end;

procedure TF_Nebel.P_VerticalClick(Sender: TObject);
begin

end;

end.

