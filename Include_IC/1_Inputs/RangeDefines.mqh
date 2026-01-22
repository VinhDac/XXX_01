// File: Include_IC\1_Inputs\RangeDefines.mqh
struct RangeSettings {
   int period; 
   
   RangeSettings() {
      period = 200;
   }
};

struct SignalResult {
   bool     is_buy;
   double   entry_price;
   double   target_price;
   double   potential_percent; 
   
   SignalResult() {
      is_buy = false;
      entry_price = 0.0;
      target_price = 0.0;
      potential_percent = 0.0;
   }
};