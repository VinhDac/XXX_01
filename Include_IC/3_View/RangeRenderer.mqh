// File: Include_IC\3_View\RangeRenderer.mqh
#include "..\1_Inputs\RangeDefines.mqh"

class CRangeRenderer {
public:
   double BuffHigh[];
   double BuffLow[];
   double BuffArrow[]; 

   void Initialize() {
      //  Buffer
      SetIndexBuffer(0, BuffHigh, INDICATOR_DATA);
      SetIndexBuffer(1, BuffLow, INDICATOR_DATA);
      SetIndexBuffer(2, BuffArrow, INDICATOR_DATA);

      // Ressistance buffer: red line
      PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetInteger(0, PLOT_LINE_COLOR, clrRed);
      PlotIndexSetInteger(0, PLOT_LINE_WIDTH, 2);
      PlotIndexSetString(0, PLOT_LABEL, "Resistance");

      // Support buffer: blue line
      PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetInteger(1, PLOT_LINE_COLOR, clrDodgerBlue);
      PlotIndexSetInteger(1, PLOT_LINE_WIDTH, 2);
      PlotIndexSetString(1, PLOT_LABEL, "Support");

      // Arrow buffer: buy signal
      PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_ARROW);
      PlotIndexSetInteger(2, PLOT_ARROW, 233); 
      PlotIndexSetInteger(2, PLOT_LINE_COLOR, clrLime);
      PlotIndexSetInteger(2, PLOT_LINE_WIDTH, 3);
      PlotIndexSetDouble(2, PLOT_EMPTY_VALUE, 0.0); 
   }

   // Return
   void DrawProfitLabel(int index, datetime time, double price, double percent) {
      string obj_name = "Profit_" + TimeToString(time);
      ObjectDelete(0, obj_name);
      
      if(ObjectCreate(0, obj_name, OBJ_TEXT, 0, time, price)) {
         ObjectSetString(0, obj_name, OBJPROP_TEXT, "Win: " + DoubleToString(percent, 2) + "%");
         ObjectSetInteger(0, obj_name, OBJPROP_COLOR, clrYellow);
         ObjectSetInteger(0, obj_name, OBJPROP_ANCHOR, ANCHOR_UPPER); 
         ObjectSetInteger(0, obj_name, OBJPROP_FONTSIZE, 9);
      }
   }
};