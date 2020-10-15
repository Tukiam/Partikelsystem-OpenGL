unit Unit2;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

Type

  TParticle = class
  private


  public
    Fx,Fy,Fz,Fxspeed,Fyspeed: Real;

    constructor Create(x,y,z: Real);
    function getx(): Real;
    function gety(): Real;
    function getz(): Real;

    procedure setx(x: Real);
    procedure sety(y: Real);
    procedure setz(z: Real);

    procedure show(x,y,z: Real);
    procedure move();


  end;

implementation

{ TParticle }

constructor TParticle.Create(x,y,z: Real);
begin
  Fx:= x;
  Fy:= y;
  Fz:= z;
  Fxspeed:= 0.05;
  Fyspeed:= 0.05;
end;
function TParticle.getx(): Real;
begin
  Result:= self.Fx;
end;

function TParticle.gety(): Real;
begin
  Result:= self.Fy;
end;

function TParticle.getz(): Real;
begin
  Result:= self.Fz;
end;

procedure TParticle.Setx(x: Real);
begin
  self.Fx:= x;
end;
procedure TParticle.Sety(y: Real);
begin
  self.Fy:= y;
end;
procedure TParticle.Setz(z: Real);
begin
  self.Fz:= z;
end;

procedure TParticle.Show(x,y,z: Real);
begin
  glcolor4f(1,1,1,1);
  glbegin(gl_points);
    glvertex3f(Fx,Fy,Fz);
  glend;
end;

procedure Tparticle.move();
begin
  self.Fx:= self.Fx+self.Fxspeed;
  self.Fy:= self.Fy+self.Fyspeed;

end;

end.

