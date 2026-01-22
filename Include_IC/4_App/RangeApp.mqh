// File: Include_IC\4_App\RangeApp.mqh

// Include (Inputs, Engine, View)
#include "..\1_Inputs\RangeDefines.mqh"
#include "..\2_Engine\RangeCalc.mqh"
#include "..\3_View\RangeRenderer.mqh"

class CRangeApp {
private:
   CRangeEngine   m_engine;
   CRangeRenderer m_view;

public:
   void Initialize(RangeSettings &settings) {
      m_engine.Initialize(settings);
      m_view.Initialize();
   }

   int OnCalculate(const int rates_total,
                   const int prev_calculated,
                   const datetime &time[],
                   const double &high[],
                   const double &low[],
                   const double &close[]) {
      
      SignalResult res;
      
      // 1. call Engine Calculate
      m_engine.Calculate(rates_total, prev_calculated, high, low, close, 
                         m_view.BuffHigh, m_view.BuffLow, res);

      // 2.Deal with Signal Result & call View to draw
      int i = rates_total - 2;
      m_view.BuffArrow[i] = 0.0; 

      if(res.is_buy) {
       
         m_view.BuffArrow[i] = low[i] - _Point * 10;
         
  
         m_view.DrawProfitLabel(i, time[i], low[i] - _Point * 30, res.potential_percent);
         
         Print("BUY SIGNAL: Price", res.entry_price, " -> Target: ", res.target_price);
      }
      
      return(rates_total);
   }
};