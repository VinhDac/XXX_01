// File: Include_IC\2_Engine\RangeCalc.mqh

// Warnings: Use .. to return to the previous folder (Include_IC)
#include "..\1_Inputs\RangeDefines.mqh"

class CRangeEngine {
private:
   RangeSettings m_settings;

public:
   void Initialize(RangeSettings &settings) {
      m_settings = settings;
   }

   void Calculate(const int rates_total,
                  const int prev_calculated,
                  const double &high[], 
                  const double &low[],
                  const double &close[],
                  double &out_high[],   // Buffer to draw Resistance
                  double &out_low[],    // Buffer to draw Support
                  SignalResult &result) // Return Signal
   {
      // 1. Calculate starting index
      int start_idx = prev_calculated - 1;
      if(start_idx < m_settings.period) start_idx = m_settings.period;

      // 2. Donchian Channel logic
      for(int i = start_idx; i < rates_total; i++) {
         // Find highest N candels before
         int highest_idx = iHighest(NULL, 0, MODE_HIGH, m_settings.period, i - m_settings.period);
         // Find lowest N candles before
         int lowest_idx  = iLowest(NULL, 0, MODE_LOW, m_settings.period, i - m_settings.period);

         out_high[i] = high[highest_idx]; // Resistance
         out_low[i]  = low[lowest_idx];   // Support
      }

      // 3. Logic find Buy Signal
      int i = rates_total - 2; 
      result.is_buy = false;

      // Logic: low price touch support line => Buy Signal
      if (low[i] <= out_low[i] + _Point * 5) { 
         result.is_buy = true;
         result.entry_price = close[i];
         result.target_price = out_high[i]; 
         
         if(result.entry_price > 0)
            result.potential_percent = ((result.target_price - result.entry_price) / result.entry_price) * 100;
      }
   }
};