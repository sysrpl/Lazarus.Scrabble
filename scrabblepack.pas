{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit ScrabblePack;

{$warn 5023 off : no warning about unused units}
interface

uses
  ScrabbleReg, ScrabbleCtrls, ImageScaling, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('ScrabbleReg', @ScrabbleReg.Register);
end;

initialization
  RegisterPackage('ScrabblePack', @Register);
end.
