#property copyright "Team Dev Range"
#property indicator_chart_window
#property indicator_buffers 3
#property indicator_plots   3

// Include file App 
#include "Include_IC\4_App\RangeApp.mqh"

// --- INPUTS ---
input int InpPeriod = 20; 

// --- OBJECT ---
CRangeApp app;

int OnInit() {
   RangeSettings settings;
   settings.period = InpPeriod;
   
   app.Initialize(settings);
   return(INIT_SUCCEEDED);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {
   
   return app.OnCalculate(rates_total, prev_calculated, time, high, low, close);
}

void OnDeinit(const int reason) {
   ObjectsDeleteAll(0, "Profit_");
}


//helloworld