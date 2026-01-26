#pragma once
// Include/View/Renderer.mqh
// NOTE: drawing and styling only. No math.

#include <ChartObjects/ChartObjectsTxtControls.mqh>

class CRenderer
{
private:
   long   m_chart;
   string m_prefix;

   string TfTag(ENUM_TIMEFRAMES tf) const
   {
      if(tf==PERIOD_MN1) return "MN1";
      if(tf==PERIOD_W1)  return "W1";
      if(tf==PERIOD_D1)  return "D1";
      return "TF";
   }

   void SafeDeleteByPrefix(const string prefix)
   {
      // Delete objects we created (name starts with prefix)
      int total = ObjectsTotal(m_chart, 0, -1);
      for(int i=total-1;i>=0;i--)
      {
         string name = ObjectName(m_chart, i, 0, -1);
         if(StringFind(name, prefix) == 0)
            ObjectDelete(m_chart, name);
      }
   }

   void DrawLabel(const string name, const string text, int x, int y, int fontSize=10)
   {
      string obj = m_prefix + name;
      if(ObjectFind(m_chart, obj) < 0)
      {
         ObjectCreate(m_chart, obj, OBJ_LABEL, 0, 0, 0);
         ObjectSetInteger(m_chart, obj, OBJPROP_CORNER, CORNER_LEFT_UPPER);
         ObjectSetInteger(m_chart, obj, OBJPROP_XDISTANCE, x);
         ObjectSetInteger(m_chart, obj, OBJPROP_YDISTANCE, y);
         ObjectSetInteger(m_chart, obj, OBJPROP_FONTSIZE, fontSize);
         ObjectSetString(m_chart, obj, OBJPROP_FONT, "Consolas");
      }
      ObjectSetString(m_chart, obj, OBJPROP_TEXT, text);
   }

   void DrawZoneRect(const string name, datetime t1, double p1, datetime t2, double p2)
   {
      string obj = m_prefix + name;
      if(ObjectFind(m_chart, obj) < 0)
      {
         ObjectCreate(m_chart, obj, OBJ_RECTANGLE, 0, t1, p1, t2, p2);
         ObjectSetInteger(m_chart, obj, OBJPROP_BACK, true);
         ObjectSetInteger(m_chart, obj, OBJPROP_FILL, true);
         ObjectSetInteger(m_chart, obj, OBJPROP_WIDTH, 1);
      }
      ObjectMove(m_chart, obj, 0, t1, p1);
      ObjectMove(m_chart, obj, 1, t2, p2);
   }

public:
   CRenderer(): m_chart(0), m_prefix("MTFRebound_") {}

   void Init(const long chart_id, const string prefix)
   {
      m_chart = chart_id;
      m_prefix = prefix;
   }

   void Clear()
   {
      SafeDeleteByPrefix(m_prefix);
   }

   void RenderLabels(const string biasText, double pullbackPct, double score,
                     const string dipStatus, const string volStatus)
   {
      DrawLabel("bias",      "Monthly Bias: " + biasText,                 10, 15, 10);
      DrawLabel("pullback",  "Weekly Pullback: " + DoubleToString(pullbackPct, 2) + "%", 10, 35, 10);
      DrawLabel("score",     "Rebound Score: " + DoubleToString(score, 0) + "/100",      10, 55, 10);
      DrawLabel("dip",       "Dip Status: " + dipStatus,                 10, 75, 10);
      DrawLabel("vol",       "Volume: " + volStatus,                     10, 95, 10);
   }

   void RenderZones(const SRZone &zones[], const string groupName, int maxDraw=25)
   {
      // Draw a horizontal rectangle that spans from earliest visible bar to far future.
      datetime t_left = (datetime)ChartGetInteger(m_chart, CHART_FIRST_VISIBLE_BAR_TIME);
      if(t_left==0) t_left = iTime(_Symbol, PERIOD_CURRENT, 200);
      datetime t_right = TimeCurrent() + 3600*24*365; // 1 year forward

      int n = ArraySize(zones);
      int count = MathMin(n, maxDraw);
      for(int i=0;i<count;i++)
      {
         string nm = groupName + "_" + TfTag(zones[i].tf) + "_" + (zones[i].is_support ? "S" : "R") + "_" + (string)i;
         DrawZoneRect(nm, t_left, zones[i].high, t_right, zones[i].low);
         // Styling: simple TF-dependent transparency via color, keep default if user customizes later.
         // (We avoid heavy styling here; user can adjust.)
      }
   }

   void RenderConsolidationBox(const ConsolidationBox &b)
   {
      if(!b.active) return;
      datetime t1=b.t_from;
      datetime t2=TimeCurrent() + 3600*24*7; // extend a bit
      DrawZoneRect("consbox", t1, b.high, t2, b.low);
      DrawLabel("conslabel", "Weekly Consolidation ("+(string)b.bars+" bars)", 10, 115, 10);
   }
};
