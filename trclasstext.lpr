uses
  trclass;

var
  tr:TTranslateBase;
  code:integer;
begin
  tr:=TTranslateBing.Create;

  
  tr.Auto    :=false;
  tr.LangSrc :='en';
  tr.LangDst :='ru';
  tr.Original:='try to translate this. What, too hard?';
  code:=tr.Translate;
  if code<>0 then
    writeln('Error (',code,'): ',tr.ResultNote)
  else
    // UTF8 encoded text
    writeln(tr.Translated);

  tr.Free;
end.
