unit iso639;

interface

function GetLangIndex (const alang:string):integer;
function GetLang      (const alang:string):string;  overload;
function GetLang      (      alang:integer):string; overload;
function GetLangAlpha2(const alang:string):string;  overload;
function GetLangAlpha2(      alang:integer):string; overload;
function GetLangAlpha3(const alang:string):string;  overload;
function GetLangAlpha3(      alang:integer):string; overload;
function GetLangName  (const alang:string):string;  overload;
function GetLangName  (      alang:integer):string; overload;

implementation


function GetLangIndex(const alang:string):integer;
begin
  result:=0;
  if Length(alang)=2 then
  else if Length(alang)=3 then
  else
end;

function GetLang(const alang:string):string;
begin
  result:=GetLang(GetLangIndex(alang));
end;

function GetLang(alang:integer):string;
begin
  result:=GetLangAlpha2(alang);
  if result='' then
    result:=GetLangAlpha3(alang);
end;

function GetLangAlpha2(const alang:string):string;
begin
  result:=GetLangAlpha2(GetLangIndex(alang)); // len=2
end;

function GetLangAlpha2(alang:integer):string;
begin
  result:=''; // len=2
end;

function GetLangAlpha3(const alang:string):string;
begin
  result:=GetLangAlpha3(GetLangIndex(alang)); // len=3
end;

function GetLangAlpha3(alang:integer):string;
begin
  result:=''; // len=3
end;

function GetLangName(const alang:string):string;
begin
  result:=GetLangName(GetLangIndex(alang)); //?? several names
end;

function GetLangName(alang:integer):string;
begin
  result:=''; //?? several names
end;

end.
