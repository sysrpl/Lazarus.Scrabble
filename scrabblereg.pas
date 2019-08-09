(********************************************************)
(*                                                      *)
(*  Get Lazarus Scrabble Example                        *)
(*  https://www.getlazarus.org                          *)
(*  Modified August 2019                                *)
(*                                                      *)
(*  Free open source software released under the LGPL   *)
(*                                                      *)
(********************************************************)

unit ScrabbleReg;

{$mode delphi}

interface

uses
  Classes, ScrabbleCtrls;

procedure Register;

implementation

uses
  LResources;

procedure Register;
begin
  {$I scrabblectrls.lrs}
  RegisterComponents('Extra', [TScrabbleBoard]);
end;

end.
