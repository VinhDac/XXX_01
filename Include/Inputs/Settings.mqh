//###<Indicators/MTF_Rebound_Indicator.mq5>
#pragma once
// Include/Inputs/Settings.mqh
// NOTE: Inputs only. No logic, no drawing.

input int    InpLookback_MN              = 120;   // Monthly candles to scan
input int    InpLookback_W1              = 260;   // Weekly candles to scan
input int    InpLookback_D1              = 400;   // Daily candles to scan

input int    InpPivotStrength            = 3;     // Swing pivot bars left/right
input double InpSR_Merge_Pips            = 50.0;  // Merge nearby S/R levels into zones (pips)

input int    InpATR_Period               = 14;    // ATR period
input int    InpTrend_MA_Period_MN       = 20;    // Monthly MA period for bias

input double InpConsolidation_ATR_Mult   = 1.2;   // Consolidation width <= ATR*mult
input int    InpConsolidation_MinBars_W1 = 6;     // Weekly bars needed for consolidation

input double InpPullback_MinPct          = 5.0;   // Pullback min (% from last W1 swing high)
input double InpPullback_MaxPct          = 25.0;  // Pullback max (%)

input int    InpVolume_MA_Period         = 20;    // Volume MA period (W1)
input double InpVolume_Spike_Mult        = 1.5;   // Volume spike threshold (Vol > MA * mult)

input bool   InpUse_OBV_Confirm          = true;  // Optional OBV confirmation
input bool   InpDraw_Zones               = true;  // Draw S/R zones
input bool   InpDraw_ConsolidationBox    = true;  // Draw weekly consolidation box
input bool   InpDraw_Labels              = true;  // Draw labels
input bool   InpAlerts                   = false; // Pop alerts on strong signal
