//+------------------------------------------------------------------+
//| MTF_Rebound_Indicator.mq5                                         |
//| Multi-timeframe Trend + S/R + Pullback + Volume confirmation      |
//| Folder structure follows the provided README.                     |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

#include "Include\Inputs\Settings.mqh"
#include "Include\App\Applications.mqh"

CApp g_app;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                          |
//+------------------------------------------------------------------+
int OnInit()
{
   g_app.Init(ChartID(), "MTFRebound_");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_app.Deinit();
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                               |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   // We recalc on every tick for now. Later we can optimize using prev_calculated.
   g_app.Tick();
   return(rates_total);
}
//+------------------------------------------------------------------+
