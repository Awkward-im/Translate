{$H+}
unit TRClass;

interface

const
  DefaultTimeout = 5000;
  DefaultResCode = 1;

type
  TTranslateBase = class
  private
    //--- Common
//    FWebHost:string;
    FDocURL:string;
    FKeyURL:string;
    FHost  :string;
    FData  :string;
    FDetect:string;

    dummy:string; //!!!!

    FNotes :string; // limits etc

    FTimeout:integer;
    FAPIKey :string;
    // language
    FAuto   :boolean;
    FFrom,
    FTo     :string;
    // text
    FText,
    FOut    :string;

    FResult :string;

    //--- Web (page translation)
    //--- Documents
    //--- Dictionary
    //--- TTS
//    FTTSURL:string;

    function  GetLang(const alang:string):string;
    procedure SetLang(index:integer; const alang:string); virtual;

    function GetResultDescr:string;

//    function GetReady():boolean; // Check for parameters? ready to translate?

//    procedure GetSupportedLangList;
  public
    // Main methods
    constructor Create; 
    function    Detect   :boolean; virtual; // Detect language of text
    function    Translate:integer; virtual; // Translate text

    // all other
    procedure RegisterKey; //?? Register API key (open web page?)
    
    //--- properties
    // common
    property Timeout:integer read FTimeout write FTimeout default DefaultTimeout;

    // changeable
    property LangAuto:boolean read FAuto write FAuto;
    property LangSrc:string index 0 read FFrom write SetLang;
    property LangDst:string index 1 read FTo   write SetLang;

    property Key:string  read FAPIKey write FAPIKey; // API key (if presents)

    // process
    property Original  :string  read FText write FText; // Original text
    property Translated:string  read FOut;              // Translated text

    property ResultNote:string  read GetResultDescr;    // Translation result description

    // personal
    property Site:string read FHost write FHost; //??

    property Notes:string read FNotes;

//    property Support; // web, translation, dictionary, speak

    // languages
    property LangList :string read dummy;
    property LangPairs:string read dummy;
  end;


//----- Yandex -----
(*
  TTS: https://tts.voicetech.yandex.net/tts?format=mp3&quality=hi&platform=web&application=translate'
  '&lang={from}-{to}&text={text}&speed=0.7'
*)
type
  TTranslateYandex = class(TTranslateBase)
  private
    Fv1Detect:string;
    Fv1Data  :string;
    Fv1KeyURL:string;
    FAppId   :string;
    
    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;// override;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- Babylon -----

type
  TTranslateBabylon = class(TTranslateBase)
  private
    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;// override;

    function Translate:integer; override;

//    property SrcLang:string index 0 read FFrom write SetLang;
//    property DstLang:string index 1 read FTo   write SetLang;
  end;

//----- MyMemory -----

type
  TTranslateMyMemory = class(TTranslateBase)
  private
    FEmail:string;
  public
    constructor Create;// override;

    function Translate:integer; override;

    property Email:string read FEmail write FEmail;
  end;

//----- Google -----

(*
  client -
  sl     - source language
  tl     - target language
  hl     - help language
  dt=at  - alternative translations
  dt=bd  - dictionary, in case source text is one word (you get translations with articles, reverse translations, etc.)
  dt=dj  - Json response with names. (dj=1)
  dt=ex  - examples
  dt=gt  - gender-specific translations
  dt=ld  - identified source languages
  dt=md  - definitions of source text, if it's one word
  dt=qc  -
  dt=qca - qc with autocorrect
  dt=rm  - transcription / transliteration of source and translated texts
  dt=rw  - 'See also' list.
  dt=ss  - synonyms of source text, if it's one word
  dt=sw  -
  dt=t   - translation of source text
  ie     - 'UTF-8',
  oe     - 'UTF-8',
  otf    - 1 / 2
  srcrom - 1
  ssel   - 0 / 3
  tsel   - 0 / 4
  kc     - 7
  q      - text
  tbb    - 1
  tk     - token 520078|504525 / 519592|450115
  prev   - btn
  rom    - 1

TTS: '/translate_tts?ie=UTF-8&q={text}&tl={to}&client=webapp&ttsspeed=0.24';

TTS: 'https://translate.googleapis.com/translate_tts?ie=UTF-8&client=gtx&sl={from}&tl={to}&q={text}&ttsspeed=0.24'
WEB: 'https://translate.google.com/translate?hl=en&sl={from}&tl={to}&u={url}'
      https://translate.google.com/translate?u={url}&langpair={from}%7C{to}&ie=UTF-8&oe=UTF-8
*)
type
  TTranslateGoogle = class(TTranslateBase)
  private
    FAPIv2Host  :string;
    FAPIv2Data  :string;
    FAPIv2Detect:string;

    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;// override;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- Bing -----

type
  TTranslateBing = class(TTranslateBase)
  private
    FFormData:string;

    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;// override;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;

//----- Prompt  -----

type
  TTranslateBing = class(TTranslateBase)
  private
    FFormData:string;

    procedure SetLang(index:integer; const alang:string); override;
  public
    constructor Create;// override;

    function Detect   :boolean; override;
    function Translate:integer; override;
  end;


//==========

implementation

uses
  sysutils,

//  LCLIntf,
  
  fphttpclient,
  opensslsockets,
  jsontools,
  iso639
  ;

resourcestring
  sWrongAPIKey   = 'Wrong API key';
  sKeyBlocked    = 'API key blocked';
  sTooMuchText   = 'Day text potion out of limit';
  sTooLongText   = 'Text length too large';
  sCantTranslate = 'Text can''t be translated';
  sWrongLanguage = 'Choosen language is unsupported';
  sUnknownError  = 'Unknown Error';

//===== TTranslateBase =====

//----- Main methods -----

constructor TTranslateBase.Create;
begin
  inherited;

  FTimeout:=DefaultTimeout;
end;

procedure TTranslateBase.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);
  if llang='auto' then
  begin
    if index=0 then
      FAuto:=true; // will changed in custom
  end
  else
  begin
    if index=0 then
    begin
      if llang<>FFrom then
      begin
        FFrom:=iso639.GetLang(llang);
        FAuto:=FFrom='';
      end;
    end
    else if llang<>FTo then
      FTo:=iso639.GetLang(llang);
  end;
end;

function TTranslateBase.Detect:boolean;
begin
  result:=false;
end;

function TTranslateBase.Translate:integer;
begin
  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end
  else
  begin
    FOut   :='';
    result :=DefaultResCode;
    FResult:=sWrongLanguage;
  end;
end;

//--- properties suppport

function TTranslateBase.GetResultDescr:string;
begin
  result:=FResult;
end;

{
procedure TTranslateBase.GetSupportedLangList;
begin
end;
}
procedure TTranslateBase.RegisterKey;
begin
//  OpenURL(FKeyURL);
end;

function TTranslateBase.GetLang(const alang:string):string;
begin
  result:=alang;
end;


//===== Yandex =====

{
200	- Операция выполнена успешно
401	- Неправильный API-ключ
402	- API-ключ заблокирован
404	- Превышено суточное ограничение на объем переведенного текста
413	- Превышен максимально допустимый размер текста
422	- Текст не может быть переведен
501	- Заданное направление перевода не поддерживается
}
constructor TTranslateYandex.Create;
begin
  inherited;

  FDocURL := 'https://yandex.ru/dev/translate/doc/dg/concepts/about-docpage/';
  FKeyURL := 'https://translate.yandex.ru/developers/keys';
  FHost   := 'https://translate.yandex.net/';
  FDetect := 'api/v1.5/tr.json/detect?text={text}&key={key}';
  FData   := 'api/v1.5/tr.json/translate?lang={from}-{to}&key={key}&text={text}';

  Fv1Data   := 'api/v1/tr.json/translate?id={appid}-0-0&srv=tr-text&lang={from}-{to}&text={text}';
  Fv1Detect := 'api/v1/tr.json/detect?sid={appid}&srv=tr-text&text={text}'; // 256 symbols
  Fv1KeyURL := 'https://oauth.yandex.ru/client/new';
  FAppId    := 'a5ab1325.5e62b3ea.9eab678d'; // Vivaldi
end;

procedure TTranslateYandex.SetLang(index:integer; const alang:string);
begin
  inherited SetLang(index,alang);
   // check the list here
end;

function TTranslateYandex.Detect:boolean;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  result:=false;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FDetect;

    if FAPIKey='' then
      ls:=StringReplace(ls,'&key={key}','',[rfReplaceAll])
    else
      ls:=StringReplace(ls,'{key}',FAPIKey,[rfReplaceAll]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.Post(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          if round(jn.Child('code').AsNumber)=200 then
          begin
            FFrom:=jn.Child('lang').AsString;
            result:=true;
          end
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;

function TTranslateYandex.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FOut:='';

  if FAPIKey='' then
  begin
    result :=401;
    FResult:=sWrongAPIKey;
    exit;
  end;

  result:=DefaultResCode;

  if FTo='' then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FData;

    ls:=StringReplace(ls,'{key}',FAPIKey,[rfReplaceAll]);

    ls:=StringReplace(ls,'{to}',FTo,[rfReplaceAll]);
    if FAuto then
    begin
      ls:=StringReplace(ls,'{from}-','',[rfReplaceAll])
    end
    else
      ls:=StringReplace(ls,'{from}' ,FFrom,[rfReplaceAll]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.Post(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          result:=round(jn.Child('code').AsNumber);
          if result=200 then
          begin
            FOut   :=jn.Child('text').AsArray.Child(0).AsString;
            result :=0;
            FResult:='';
          end
          else
          begin
            case result of
              401: FResult:=sWrongAPIKey;
              402: FResult:=sKeyBlocked;
              404: FResult:=sTooMuchText;
              413: FResult:=sTooLongText;
              422: FResult:=sCantTranslate;
              501: FResult:=sWrongLanguage;
            else
              FResult:=sUnknownError+' '+IntToStr(result);
            end;
          end;
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;

//===== Babylon =====

const
  SupLangBabylon: array of packed record lang:array [0..1] of char; code:word; end = (
   (lang:'en';code: 0), (lang:'ru';code: 7), (lang:'ar';code:15), (lang:'ca';code:99),
   (lang:'zh';code:10), (lang:'cs';code:31), (lang:'da';code:43), (lang:'nl';code: 4),
   (lang:'de';code: 6), (lang:'el';code:11), (lang:'he';code:14), (lang:'hi';code:60),
   (lang:'hu';code:30), (lang:'it';code: 2), (lang:'ja';code: 8), (lang:'ko';code:12),
   (lang:'no';code:46), (lang:'fa';code:51), (lang:'pl';code:29), (lang:'pt';code: 5),
   (lang:'ro';code:47), (lang:'es';code: 3), (lang:'sv';code:48), (lang:'th';code:16),
   (lang:'tr';code:13), (lang:'uk';code:49), (lang:'ur';code:39)
  );

constructor TTranslateBabylon.Create;
begin
  inherited;

  FHost := 'https://translation.babylon-software.com/';
  FData := 'translate/babylon.php?v=1.0&callback=callbackFn&context=babylon'+
           '&langpair={from}%7C{to}&q={text}';
end;

procedure TTranslateBabylon.SetLang(index:integer; const alang:string);
var
  llang:string;
  ls:string[3];
  i,j:integer;
begin
  llang:=LowerCase(alang);

  i:=-1;
  case llang of
    'zh-cn': i:=10;
    'zh-tw': i:=9;
  else
    ls:=iso639.GetLangA2(llang);
    if ls<>'' then
    begin
      for j:=0 to High(SupLangBabylon) do
      begin
        if (ls[1]=SupLangBabylon[j].lang[0]) and
           (ls[2]=SupLangBabylon[j].lang[1]) then
        begin
          i:=SupLangBabylon[j].code;
          break;
        end;
      end;
    end;
  end;

  if i>=0 then
  begin
    Str(SupLangBabylon[j].code,ls);
    if index=0 then
      FFrom:=ls
    else
      FTo:=ls;
  end;
end;

function TTranslateBabylon.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  FOut:='';
  result:=DefaultResCode;

  if FAuto or (FFrom='') or (FTo='') then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FData;
    ls:=StringReplace(ls,'{to}'  ,FTo  ,[rfReplaceAll]);
    ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.Get(FHost+ls);

    ls:=Copy(ls,11); // skip 'callbackFn'
    SetLength(ls,Length(ls)-1);
    ls[1]:='[';
    ls[Length(ls)]:=']';

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(ls) then
      begin
        result:=round(jn.AsArray.Child(2).AsNumber);
        if result=200 then
        begin
          FOut:=jn.AsArray.Child(1).Child('translatedText').AsString;
          FResult:='';
          result:=0;
        end
        else
          FResult:=sUnknownError+' '+IntToStr(result);
      end;
    finally
      jn.Free;
    end;

  except
  end;
  ltr.Free;
end;

//===== MyMemory =====

constructor TTranslateMyMemory.Create;
begin
  inherited;

  FDocURL:='https://mymemory.translated.net/doc/spec.php';
  FKeyURL:='https://mymemory.translated.net/doc/keygen.php';
  
  FHost := 'https://api.mymemory.translated.net/';
  FData := 'get?q={text}&langpair={from}%7C{to}&key={key}&de={email}';
end;

function TTranslateMyMemory.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  FOut:='';
  result:=DefaultResCode;

  if FAuto or (FFrom='') or (FTo='') then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FData;

    if FEmail='' then
      ls:=StringReplace(ls,'&de={email}','',[rfReplaceAll])
    else
      ls:=StringReplace(ls,'{email}',FEMail,[rfReplaceAll]);

    if FAPIKey='' then
      ls:=StringReplace(ls,'&key={key}','',[rfReplaceAll])
    else
      ls:=StringReplace(ls,'{key}',FAPIKey,[rfReplaceAll]);

    ls:=StringReplace(ls,'{to}'  ,FTo  ,[rfReplaceAll]);
    ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.Get(FHost+ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          jl:=jn.Child('responseStatus');
          if jl<>nil then
            result:=round(jl.AsNumber);

          if result=200 then
          begin
            jl:=jn.Find('responseData/translatedText');
            if jl<>nil then
            begin
              FOut   :=jl.AsString;
              result :=0;
              FResult:='';
            end;
          end
          else
            // 403 - invalid language pair
            FResult:=sUnknownError+' '+IntToStr(result);
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;

//===== Google =====

constructor TTranslateGoogle.Create;
begin
  inherited;

  FKeyUrl:='';

  FAPIv2Host  := 'https://translation.googleapis.com/';
  FAPIv2Data  := 'language/translate/v2?key={key}&q={text}&source={from}&target={to}';
  FAPIv2Detect:= 'language/translate/v2/detect?key={key}&q={text}';

  FHost  := 'https://translate.google.com/';
  FDetect:= 'translate_a/single?client=x&sl=auto&dt=ld&ie=UTF-8&oe=UTF-8&q={text}';
  FData  := 'translate_a/single?client=x&sl={from}&tl={to}&hl=en'+
//    '&dt=bd&dt=ex&dt=ld&dt=md&dt=qc&dt=rw&dt=rm&dt=ss&dt=t&dt=at'+
    '&dt=t&dt=ld&ie=UTF-8&oe=UTF-8&q={text}';
end;

procedure TTranslateGoogle.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);

  case llang of
    'zh-cn',
    'zh-tw': begin
      if index=0 then
        FFrom:=llang
      else
        FTo:=llang;
    end;
  else
    inherited SetLang(index,alang);
  end;
end;

function TTranslateGoogle.Detect:boolean;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  result:=false;

  if FAPIKey='' then
  begin
    ltr:=TFPHTTPClient.Create(nil);
    try
      ltr.IOTimeout:=FTimeout;

      ls:=FDetect;
      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

      ls:=ltr.Get(FHost+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            jl:=jn.Find('8/0/0');
            if jl<>nil then
            begin
              FFrom:=jn.AsString;
              result:=true;
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    except
    end;
    ltr.Free;

  end
  else
  begin
    ltr:=TFPHTTPClient.Create(nil);
    try
      ltr.IOTimeout:=FTimeout;

      ls:=FAPIv2Detect;

      ls:=StringReplace(ls,'{key}' ,FAPIKey,[rfReplaceAll]);
      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

      ls:=ltr.Post(FAPIv2Host+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            jl:=jn.Find('data/detections/0/language');
            if jl<>nil then
            begin
              FFrom:=jl.AsString;
              result:=true;
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    except
    end;
    ltr.Free;
  end;
end;

function TTranslateGoogle.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl,jc:TJsonNode;
begin
  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FOut:='';
  result:=DefaultResCode;

  if FTo='' then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    if FAPIKey='' then
    begin
      //--- Free version

      ls:=FData;
      ls:=StringReplace(ls,'{to}',FTo,[rfReplaceAll]);

      if FAuto then
        ls:=StringReplace(ls,'{from}','auto',[rfReplaceAll])
      else
        ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);

      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

      ls:=ltr.Get(FHost+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            if FAuto then
            begin
              jl:=jn.Find('8/0/0');
              if jl<>nil then
                FFrom:=jn.AsString;
            end;
            jl:=jn.Child(0);
            if jl.Kind<>nkNull then
            begin
              for jc in jl do
                FOut:=FOut+jc.Child(0).AsString;
              result :=0;
              FResult:='';
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    end
    else
    begin
      //--- Paid API version
      ls:=FAPIv2Data;
      ls:=StringReplace(ls,'{key}',FAPIKey,[rfReplaceAll]);

      ls:=StringReplace(ls,'{to}',FTo,[rfReplaceAll]);

      if FAuto then
        ls:=StringReplace(ls,'&source={from}','',[rfReplaceAll])
      else
        ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);

      ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

      ls:=ltr.Get(FAPIv2Host+ls);

      if ls<>'' then
      begin
        jn:=TJsonNode.Create;
        try
          if jn.TryParse(ls) then
          begin
            if FAuto then
            begin
              jl:=jn.Find('data/translations/0/detectedSourceLanguage');
              if jl<>nil then
                FFrom:=jl.AsString;
            end;
            jl:=jn.Find('data/translations/0/translatedText');
            if jl<>nil then
            begin
              FOut   :=jl.AsString;
              result :=0;
              FResult:='';
            end;
          end;
        finally
          jn.Free;
        end;
      end;

    end;

  except
  end;
  ltr.Free;
end;

//===== Bing =====

constructor TTranslateBing.Create;
begin
  inherited;

  FDocURL   := '';
  FKeyURL   := '';
  FHost     := 'https://www.bing.com/';
  FDetect   := '';
  FData     := 'ttranslatev3/';
  FFormData := 'text={text}&fromLang={from}&to={to}';

end;

procedure TTranslateBing.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  llang:=LowerCase(alang);

  case llang of
    'zh-cn': llang:='zh-Hans';
    'zh-tw': llang:='zh-Hant';
  else
    inherited SetLang(index,alang);
    // here lang separated to [From/To] already
    if index=0 then
    begin
      case FFrom of
        'bs': FFrom:='bs-Latn';
        'no': FFrom:='nb';      //?? awk, not js
        'pt': FFrom:='pt-pt';   //?? awk, not js
        'sr': FFrom:='sr-Cyrl'; //?? js, not awk
      end;
    end
    else
    begin
      case FTo of
        'bs': FTo:='bs-Latn';
        'no': FTo:='nb';      //?? awk, not js
        'pt': FTo:='pt-pt';   //?? awk, not js
        'sr': FTo:='sr-Cyrl'; //?? js, not awk
      end;
    end;

    exit;
  end;

  if index=0 then
    FFrom:=llang
  else
    FTo:=llang;
end;

function TTranslateBing.Detect:boolean;
{
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
}
begin
  result:=inherited;
(*
  result:=false;
  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FDetect;

    ls:=StringReplace(ls,'{from}','auto-detect',[rfReplaceAll])
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.FormPost(FHost,ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
*)
end;

function TTranslateBing.Translate:integer;
var
  ls:AnsiString;
  ltr:TFPHTTPClient;
  jn,jl:TJsonNode;
begin
  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FOut:='';

  result:=DefaultResCode;

  if FTo='' then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FFormData;

    ls:=StringReplace(ls,'{to}',FTo,[rfReplaceAll]);
    if FAuto then
    begin
      ls:=StringReplace(ls,'{from}','auto-detect',[rfReplaceAll])
    end
    else
      ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);

    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.FormPost(FHost+FData,ls);

    if ls<>'' then
    begin
      jn:=TJsonNode.Create;
      try
        if jn.TryParse(ls) then
        begin
          if FAuto then
          begin
            jl:=jn.Find('0/detectedLanguage/language');
            if jl<>nil then
              FFrom:=jl.AsString;
          end;
          jl:=jn.Find('0/translations/0/text');
          if jl<>nil then
          begin
            FOut   :=jl.AsString;
            result :=0;
            FResult:='';
          end;
        end;
      finally
        jn.Free;
      end;
    end;

  except
  end;
  ltr.Free;
end;

//===== Prompt =====

constructor TTranslateBabylon.Create;
begin
  inherited;

  FHost := 'https://www.online-translator.com';
  FData := '/services/soap.asmx/GetTranslation';
  FFormData := '';
end;

procedure TTranslatePrompt.SetLang(index:integer; const alang:string);
var
  llang:string;
begin
  inherited SetLang(index,alang);
end;

function TTranslatePrompt.Translate:integer;
var
  ls:string;
  ltr:TFPHTTPClient;
  jn:TJsonNode;
begin
  FOut:='';
  result:=DefaultResCode;

  if FAuto or (FFrom='') or (FTo='') then
  begin
    FResult:=sWrongLanguage;
    exit;
  end;

  if (FFrom=FTo) or (FText='') then
  begin
    FOut:=FText;
    FResult:='';
    result:=0;
  end;

  FResult:=sUnknownError;

  ltr:=TFPHTTPClient.Create(nil);
  try
    ltr.IOTimeout:=FTimeout;

    ls:=FFormData;
    ls:=StringReplace(ls,'{to}'  ,FTo  ,[rfReplaceAll]);
    ls:=StringReplace(ls,'{from}',FFrom,[rfReplaceAll]);
    ls:=StringReplace(ls,'{text}',EncodeURLElement(FText),[rfReplaceAll]);

    ls:=ltr.FormPost(FHost+FData,ls);

    jn:=TJsonNode.Create;
    try
      if jn.TryParse(ls) then
      begin
{
        result:=round(jn.AsArray.Child(2).AsNumber);
        if result=200 then
        begin
          FOut:=jn.AsArray.Child(1).Child('translatedText').AsString;
          FResult:='';
          result:=0;
        end
        else
          FResult:=sUnknownError+' '+IntToStr(result);
}
      end;
    finally
      jn.Free;
    end;

  except
  end;
  ltr.Free;
end;

end.
