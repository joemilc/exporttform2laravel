{ CRIADA POR JOEMIL }
unit uFuncoes_Laravel;

interface

uses Forms, Classes, Vcl.Controls, Vcl.StdCtrls, ZDataset, uFuncoes, SysUtils,
  ExtCtrls, TypInfo, RxLookup;

procedure GeraScriptLaravel;
function DivEdit(AField: String): String;
function DivCombo(AQuery: TZQuery): String;
function DivCheckBox(ATexto, AField: String): String;

implementation

uses
  DBCtrls, RxDBComb, PCheck;

procedure GeraScriptLaravel;
const
  LISTA_EDITS = 'TEDIT,TMAKSEDIT,TMEMO';
  LISTA_DBEDITS = 'TDBEDIT,TDBMAKSEDIT,TDBMEMO';
  LISTA_COMBOS = 'TCOMBOBOX,TRXCOMBOBOX,';
  LISTA_DBCOMBOS = 'TDBCOMBOBOX,TRXDBCOMBOBOX';
  LISTA_LOOKUP = 'TDBLOOKUPCOMBOBOX,TRXDBLOOKUPCOMBO';
  LISTA_CHECKBOX = 'TCHECKBOX,TPCHECK';
  LISTA_DBCHECKBOX = 'TDBCHECKBOX';
  LISTA_MEMOS = 'TMEMO,TRICHEDIT';
  LISTA_DBMEMOS = 'TDBMEMO,TDBRICHEDIT';

var
  x, i: Integer;
  AForm: TForm;
  AComp: TComponent;
  AWinControl: TWinControl;
  sField, sCaption, sTipo, AName: String;
  ALabel: TLabel;
  xTop, ATop, ALeft: Integer;
  sDiv, Texto, Laravel, FileName: String;
  Arq: TextFile;
  sGroup: String;
  bComp: Boolean;
  Qry: TZQuery;
  TODOS_EDITS: String;
begin
  TODOS_EDITS := Format('%s,%s,%s,%s,%s, %S,%S,%S,%S', [LISTA_EDITS, LISTA_DBEDITS, LISTA_COMBOS,
    LISTA_DBCOMBOS,LISTA_LOOKUP,LISTA_CHECKBOX, LISTA_DBCHECKBOX, LISTA_MEMOS, LISTA_DBMEMOS]);
  AForm := Screen.ActiveForm;
  ExecutarSQL('TRUNCATE topsapp.laravel');
  Qry := CriarQueryTemporaria(true, 'SELECT * FROM topsapp.laravel WHERE form = ' + QuotedStr(AForm.Name));
  Qry.CachedUpdates := true;

  Laravel := '';
  Texto := '';
  ATop := 0;
  for x := 0 to AForm.ComponentCount - 1 do
  begin
    AComp := AForm.Components[x];
    if AComp IS TWinControl then
    begin
      AWinControl := TWinControl(AComp);
      AName := UpperCase(AWinControl.ToString);
      if Pos(AName, TODOS_EDITS) > 0 then
      begin
        Qry.Append;
        Qry.FieldByName('form').AsString := AForm.Name;
        Qry.FieldByName('tipo').AsString := AWinControl.ToString;
        Qry.FieldByName('componente').AsString := AWinControl.Name;
        Qry.FieldByName('parent').AsString := AWinControl.Parent.Name;
        Qry.FieldByName('itop').Value := AWinControl.Top;
        Qry.FieldByName('iLeft').Value := AWinControl.Left;

        if (AWinControl.Parent is TPanel) then
          Qry.FieldByName('parent').AsString := AWinControl.Parent.Parent.Name;

        if AName = 'TCHECKBOX' then
          Qry.FieldByName('texto').Value := TCheckBox(AComp).Caption
        else if AName = 'TDBCHECKBOX' then
        begin
          Qry.FieldByName('texto').Value := TDBCheckBox(AComp).Caption;
          Qry.FieldByName('field_name').AsString := TDBCheckBox(AComp).DataField;
        end
        else if AName = 'TPCHECK' then
          Qry.FieldByName('texto').Value := TPCheck(AComp).Caption
        else if AName = 'TDBEDIT' then
          Qry.FieldByName('field_name').AsString := TDBEdit(AComp).DataField
        else if AName = 'TDBCOMBOBOX' then
        begin
          Qry.FieldByName('field_name').AsString := TDBComboBox(AComp).DataField;
          Qry.FieldByName('items').AsString := TDBComboBox(AComp).Items.ToString;
          Qry.FieldByName('valores').AsString := TDBComboBox(AComp).Items.ToString;
        end
        else if AName = 'TRXDBCOMBOBOX' then
        begin
          Qry.FieldByName('field_name').AsString := TRxDBComboBox(AComp).DataField;
          Qry.FieldByName('items').AsString := TRxDBComboBox(AComp).Items.Text;
          if TRxDBComboBox(AComp).Values.ToString <> '' then
            Qry.FieldByName('valores').AsString := TRxDBComboBox(AComp).Values.Text
          else
            Qry.FieldByName('valores').AsString := TRxDBComboBox(AComp).Items.Text;
        end
        else if AName = 'TDBLOOKUPCOMBOBOX' then
          Qry.FieldByName('field_name').AsString := TDBLookUpComboBox(AComp).DataField
        else if AName = 'TRXDBLOOKUPCOMBO' then
          Qry.FieldByName('field_name').AsString := TRxDBLookUpCombo(AComp).DataField
        else if AName = 'TDBMEMO' then
          Qry.FieldByName('field_name').AsString := TDBMemo(AComp).DataField
        else if AName = 'TDBRICHEDIT' then
          Qry.FieldByName('field_name').AsString := TdbRichEdit(AComp).DataField;

        Qry.Post;
      end;
    end;
  end;

  for x := 0 to AForm.ComponentCount - 1 do
  begin
    AComp := AForm.Components[x];
    bComp := False;
    if AComp IS TLabel then
    begin
      ALabel := TLabel(AComp);
      ATop := ALabel.Top;
      ALeft := ALabel.Left;
      Qry.Filter := '(iTOP >= ' + IntToStr(ATop + 10) + ' AND iTOP <= ' + IntToStr(ATop + 20) + ')' +
        ' AND (iLEFT>= ' + IntToStr(ALeft - 5) + ' AND iLEFT <= ' + IntToStr(ALeft + 5) + ')'+
        ' AND (NOT tipo LIKE ''*CHECK*'')';
      Qry.Filtered := true;
      if not Qry.IsEmpty then
      begin
        Qry.Edit;
        Qry.FieldByName('texto').AsString := ALabel.Caption;
        Qry.Post;
      end;
    end;
  end;
  ZAtualiza(Qry);
  Qry.Filtered := False;

  // gera o BLADE.PHP
  ATop := 0;
  Laravel := '';
  Qry.SortedFields := 'iTop;iLeft';
  Qry.First;
  while not Qry.Eof do
  begin
    x := Qry.FieldByName('iTop').Value;
    if (not(ATop in [x - 5 .. x + 15])) then
      Texto := '';
    sTipo := UpperCase(Qry.FieldByName('tipo').AsString);
    sCaption := Qry.FieldByName('texto').AsString;
    if Pos(sTipo, TODOS_EDITS) > 0 then
    begin
      sField := coalesce(Qry.FieldByName('field_name').AsString, Qry.FieldByName('componente').AsString);
      {if Pos('CHECKBOX', sTipo) = 0 then
      begin
        sDiv := DivCheckBox(sCaption, sField);
      end
      else}
      begin
        sDiv := '  <div class="col-lg-2">' + #13 +
          '    <label class="">' + sCaption  + '</label>' + #13;
        if Pos(sTipo, Format('%s,%s,%s,%s',[LISTA_EDITS,LISTA_DBEDITS, LISTA_MEMOS, LISTA_DBMEMOS])) > 0 then
          sDiv := sDiv + DivEdit(sField)
        else if Pos(sTipo, Format('%s,%s,%s', [LISTA_COMBOS,LISTA_DBCOMBOS, LISTA_LOOKUP])) > 0 then
          sDiv := sDiv + DivCombo(Qry);
        sDiv := sDiv  + '  </div>' + #13;
      end;
    end;
    Texto := Texto + sDiv;
    ATop := x;
    Qry.Next;
    if (Qry.Eof) or (Qry.FieldByName('iTop').AsInteger > x + 15) then
      Laravel := Laravel + '<div class="form-group row">' + #13 + Texto + '</div>' + #13;
  end;

  Qry.Close;
  FreeAndNil(Qry);

  FileName := 'e:\' + AForm.Name + '.blade.php';
  AssignFile(Arq, FileName);
  Rewrite(Arq);
  WriteLn(Arq, Laravel);
  CloseFile(Arq);

  MostraMensagem('Arquivo gerado:' + #13 + FileName);

end;

// http://www.andrecelestino.com/delphi-usando-rtti-para-exibir-dados-de-um-objeto-de-negocio-em-componentes-visuais/

function DivEdit(AField: String): String;
begin
  Result := StringReplace('    <input type="text" class="form-control" name="sField" '+
    'id="sField" value="{{ trim(old(''sField'', ((isset($dadosObj[''sField''])) ? '+
    '$dadosObj[''sField''] : ''))) }}">',
    'sField',
    AField,
    [rfReplaceAll, rfIgnoreCase]);
end;

function DivCombo(AQuery: TZQuery): String;
var
  sField: String;
  MemoI, MemoV: TStrings;
  i: Integer;
begin
  sField := Coalesce(AQuery.FieldByName('field_name').AsString, AQuery.FieldByName('componente').AsString);
  MemoI := TStringList.Create;
  MemoV := TStringList.Create;
  Result := StringReplace('    <select class="form-control kt-selectpicker" name="sField" id="sField" title="Selecione">',
    'sField',sField, [rfReplaceAll, rfIgnoreCase])+#13;
  MemoI.Text := AQuery.FieldByName('items').AsString;
  MemoV.Text := AQuery.FieldByName('valores').AsString;
  for i := 0 to MemoI.Count - 1 do
    Result := Result + '    <option value="' + MemoV[i] + '" @if((isset($dadosObj[' + QuotedStr(sField) +
      ']) ? trim($dadosObj[' + QuotedStr(sField) + ']) : "") == "' + MemoV[i] + '") selected @endif>' + MemoI[i] +
      '</option>' + #13;
  MemoI.Free;
  MemoV.Free;
end;

function DivCheckBox(ATexto, AField: String): String;
begin
  Result :=
    '  <div class="col-lg-auto">'+#13+
    '    <label style="color: white;">.</label>'+#13+
    '    <div class="kt-checkbox-inline" style="margin-top: 10px;">'+#13+
    '      <label class="kt-checkbox kt-checkbox--brand">'+#13+
    '        <input type="checkbox" name="sField" id="sField" value="true" '+
               '@if((isset($dadosObj[''sField'']) ? trim($dadosObj[''sField'']) : "") == "S") '+
               'checked="checked" @endif>'+ATexto+#13+
    '        <span></span>'+#13+
    '      </label>'+#13+
    '    </div>'+#13+
    '  </div>'+#13;

  Result := StringReplace(Result, 'sField', AField, [rfReplaceAll, rfIgnoreCase]);
end;

end.
