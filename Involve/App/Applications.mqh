//###<Indicators/MTF_Rebound_Indicator.mq5>
#pragma once
// Include/App/Applications.mqh
// NOTE: Manager that connects Engine (Calculations) and View (Renderer).

#include "..\Engine\Calculations.mqh"
#include "..\View\Renderer.mqh"
#include "..\Inputs\Settings.mqh"

class CApp
{
private:
   CCalculations m_calc;
   CRenderer     m_view;
   long          m_chart;
   string        m_prefix;

   string BiasToText(ENUM_BIAS_STATE b) const
   {
      if(b==BIAS_UP) return "Up";
      if(b==BIAS_DOWN) return "Down";
      return "Sideways";
   }

public:
   CApp(): m_chart(0), m_prefix("MTFRebound_") {}

   void Init(const long chart_id, const string prefix)
   {
      m_chart = chart_id;
      m_prefix = prefix;
      m_view.Init(chart_id, prefix);
   }

   void Deinit()
   {
      m_view.Clear();
   }

   void Tick()
   {
      // Run core calculations
      m_calc.UpdateAll(
         InpLookback_MN, InpLookback_W1, InpLookback_D1,
         InpPivotStrength, InpSR_Merge_Pips,
         InpTrend_MA_Period_MN, InpATR_Period,
         InpConsolidation_MinBars_W1, InpConsolidation_ATR_Mult,
         InpPullback_MinPct, InpPullback_MaxPct,
         InpVolume_MA_Period, InpVolume_Spike_Mult,
         InpUse_OBV_Confirm
      );

      // Draw
      if(InpDraw_Labels)
         m_view.RenderLabels(BiasToText(m_calc.Bias), m_calc.PullbackPct, m_calc.ReboundScore, m_calc.DipStatus, m_calc.VolumeStatus);

      if(InpDraw_Zones)
      {
         m_view.RenderZones(m_calc.ZonesMN_Support, "zonesMN_S");
         m_view.RenderZones(m_calc.ZonesMN_Resist,  "zonesMN_R");
         m_view.RenderZones(m_calc.ZonesW1_Support, "zonesW1_S");
         m_view.RenderZones(m_calc.ZonesW1_Resist,  "zonesW1_R");
         m_view.RenderZones(m_calc.ZonesD1_Support, "zonesD1_S");
         m_view.RenderZones(m_calc.ZonesD1_Resist,  "zonesD1_R");
      }

      if(InpDraw_ConsolidationBox)
         m_view.RenderConsolidationBox(m_calc.ConsBox);

      // Alerts (optional)
      if(InpAlerts)
      {
         if(m_calc.Bias==BIAS_UP && m_calc.ReboundScore>=70.0 && m_calc.DipStatus!="Falling")
            Alert("MTF Rebound: Strong setup (Score ", DoubleToString(m_calc.ReboundScore,0), "/100) on ", _Symbol);
      }
   }
};
