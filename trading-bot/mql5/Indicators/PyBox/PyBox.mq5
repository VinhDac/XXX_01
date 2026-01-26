#property strict

input string API_URL = "http://127.0.0.1:8000/box";
input string API_KEY = "change-me";

input int REFRESH_SECONDS = 2;
input int BOX_MINUTES = 30;
input int BOX_POINTS  = 200;

string BoxName() { return "PYBOX_EA_STEP1_" + _Symbol + "_" + IntegerToString((int)_Period); }

// Minimal JSON number extractor: "box_high":123.45
bool JsonGetNumber(const string &json, const string &key, double &out)
{
   int k = StringFind(json, "\"" + key + "\"");
   if(k < 0) return false;
   int c = StringFind(json, ":", k);
   if(c < 0) return false;

   int i = c + 1;
   while(i < StringLen(json) && (StringGetCharacter(json,i) == ' ')) i++;

   string num = "";
   while(i < StringLen(json))
   {
      ushort ch = (ushort)StringGetCharacter(json,i);
      if(ch==',' || ch=='}' || ch==' ' || ch=='\r' || ch=='\n') break;
      num += (string)CharToString((char)ch);
      i++;
   }
   out = StringToDouble(num);
   return true;
}

bool JsonGetString(const string &json, const string &key, string &out)
{
   int k = StringFind(json, "\"" + key + "\"");
   if(k < 0) return false;
   int c = StringFind(json, ":", k);
   if(c < 0) return false;

   int q1 = StringFind(json, "\"", c+1);
   if(q1 < 0) return false;
   int q2 = StringFind(json, "\"", q1+1);
   if(q2 < 0) return false;

   out = StringSubstr(json, q1+1, q2-q1-1);
   return true;
}

int OnInit()
{
   Print("PyBoxEA Step1: OnInit OK");
   EventSetTimer(REFRESH_SECONDS);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectDelete(0, BoxName());
}

void OnTimer()
{
   double bid   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double mid   = (bid + ask) / 2.0;
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   string body =
      "{"
      "\"symbol\":\"" + _Symbol + "\","
      "\"timeframe\":\"" + IntegerToString((int)_Period) + "\","
      "\"mid\":" + DoubleToString(mid, _Digits) + ","
      "\"point\":" + DoubleToString(point, 10) + ","
      "\"digits\":" + IntegerToString(_Digits) + ","
      "\"box_points\":" + IntegerToString(BOX_POINTS) + ","
      "\"box_minutes\":" + IntegerToString(BOX_MINUTES) +
      "}";

   string headers =
      "Content-Type: application/json\r\n"
      "X-API-Key: " + API_KEY + "\r\n";

    char post[];
    int len = StringToCharArray(body, post, 0, WHOLE_ARRAY, CP_UTF8);
    // StringToCharArray includes the terminating '\0' → remove it
    if(len > 0) ArrayResize(post, len - 1);

    char result[];
    ResetLastError();
    string result_headers;
    int status = WebRequest("POST", API_URL, headers, 5000, post, result, result_headers);


   if(status == -1)
   {
      Print("PyBoxEA Step1: WebRequest FAILED err=", GetLastError());
      return;
   }

   string resp = CharArrayToString(result);
   Print("PyBoxEA Step1: resp=", resp);

   string state;
   if(!JsonGetString(resp, "state", state)) return;
   if(state != "CONSOLIDATING") { ObjectDelete(0, BoxName()); return; }

   double boxHigh, boxLow;
   if(!JsonGetNumber(resp, "box_high", boxHigh)) return;
   if(!JsonGetNumber(resp, "box_low",  boxLow))  return;

   datetime t2 = TimeCurrent();
   datetime t1 = t2 - (BOX_MINUTES * 60);

   string name = BoxName();

   if(ObjectFind(0, name) < 0)
   {
      ResetLastError();
      bool ok = ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, boxHigh, t2, boxLow);
      Print("PyBoxEA Step1: ObjectCreate ok=", ok, " err=", GetLastError());
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrAqua);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
   }
   else
   {
      ObjectMove(0, name, 0, t1, boxHigh);
      ObjectMove(0, name, 1, t2, boxLow);
   }
}
