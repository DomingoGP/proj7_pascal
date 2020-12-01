{ Test app for proj api version 6.

  Copyright (c) 2020 Domingo Galmés

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to
  deal in the Software without restriction, including without limitation the
  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
  sell copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
  IN THE SOFTWARE.
}

unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  proj;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnCalc: TButton;
    btnSetup: TButton;
    btnInfo: TButton;
    cbInverse: TCheckBox;
    Edit1: TEdit;
    Edit2: TEdit;
    edFrom: TEdit;
    edTo: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    rgBefore: TRadioGroup;
    rgAfter: TRadioGroup;
    procedure btnCalcClick(Sender: TObject);
    procedure btnSetupClick(Sender: TObject);
    procedure btnInfoClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    P: PPJ;
    c, c_out: PJ_COORD;
    procedure SetupConversion;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
var
  Paths: array of pansichar;
begin
  DefaultFormatSettings.DecimalSeparator := '.';
  DefaultFormatSettings.ThousandSeparator := ',';

  Memo1.Lines.Add(proj_get_pj_release);
  SetLength(Paths, 1);
  Paths[0] := pansichar('C:\OSGeo4W\share\proj');   //default path in MSWINDOWS.
  {
  It is IMPORTANT to put the path to the proj data, otherwise it gives a file not found error.
  You also can set the PROJ_LIB var from Operating system.
  SET PROJ_LIB=C:\OSGeo4W\share\proj
  }
  proj_context_set_search_paths(PJ_DEFAULT_CTX, 1, @Paths[0]);

  SetupConversion;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  proj_destroy(P);
  proj_cleanup;
end;

procedure TForm1.SetupConversion;
var
  P_for_GIS: PPJ;
begin
  if P <> nil then
    proj_destroy(P);

  // two CRS.
  //P := proj_create_crs_to_crs(PJ_DEFAULT_CTX,
  //                           '+proj=longlat +ellps=clrs66',
  //                           '+proj=merc +ellps=clrk66 +lat_ts=33',
  //                           nil);
  P := proj_create_crs_to_crs(PJ_DEFAULT_CTX, pansichar(edFrom.Text), pansichar(edTo.Text), nil);
  if P = nil then
  begin
    Memo1.Lines.Add('Error  p=nil');
    Memo1.Lines.Add('Error: ' + IntToStr(proj_context_errno(PJ_DEFAULT_CTX)));
    Memo1.Lines.Add(proj_errno_string(proj_context_errno(PJ_DEFAULT_CTX)));
    exit;
  end;
  P_for_GIS := proj_normalize_for_visualization(PJ_DEFAULT_CTX, P);
  if P_for_GIS = nil then
  begin
    proj_destroy(P);
  end;
  proj_destroy(P);
  P := P_for_GIS;

end;

procedure TForm1.btnCalcClick(Sender: TObject);
begin
  c.lpzt.lam := StrToFloat(edit1.Text);
  c.lpzt.phi := StrToFloat(edit2.Text);
  if rgBefore.ItemIndex = 1 then
  begin
    c.lpzt.lam := proj_torad(c.lpzt.lam);
    c.lpzt.phi := proj_torad(c.lpzt.phi);
  end;
  if rgBefore.ItemIndex = 2 then
  begin
    c.lpzt.lam := proj_todeg(c.lpzt.lam);
    c.lpzt.phi := proj_todeg(c.lpzt.phi);
  end;
  c.lpzt.z := 0.0;
  c.lpzt.t := HUGE_VAL;
  if not cbInverse.Checked then
    c_out := proj_trans(P, PJ_FWD, c)
  else
    c_out := proj_trans(P, PJ_INV, c);

  if rgAfter.ItemIndex = 1 then
  begin
    c_out.xy.x := proj_torad(c_out.xy.x);
    c_out.xy.y := proj_torad(c_out.xy.y);
  end;
  if rgAfter.ItemIndex = 2 then
  begin
    c_out.xy.x := proj_todeg(c_out.xy.x);
    c_out.xy.y := proj_todeg(c_out.xy.y);
  end;
  Memo1.Lines.Add(FloatToStr(c_out.xy.x) + '     ' + FloatToSTr(c_out.xy.y));
end;

procedure TForm1.btnSetupClick(Sender: TObject);
begin
  SetupConversion;
end;

procedure TForm1.btnInfoClick(Sender: TObject);
var
  options: array[0..1] of PAnsiChar=('MULTILINE=YES',nil);
  texto: ansistring;
begin
  texto := proj_as_proj_string(PJ_DEFAULT_CTX, P, PJ_PROJ_5, nil);
  texto := texto + #13#10 + #13#10;
  //options[0] := 'MULTILINE=YES'#0;
  //options[1] := nil;
  texto := texto + proj_as_wkt(PJ_DEFAULT_CTX, P, PJ_WKT2_2019, @options[0]);
  Memo1.Lines.Text := texto;
end;

end.
