//+------------------------------------------------------------------+
//|                                              ConsolidationBox.mq5 |
//| Draws the most recent consolidation rectangle before an UP breakout |
//+------------------------------------------------------------------+
#property indicator_chart_window
#property indicator_plots 0

input int      InpLookbackBars          = 200;    // How many closed bars to scan
input int      InpMinConsolBars         = 6;      // Min bars in consolidation
input int      InpMaxConsolBars         = 20;     // Max bars in consolidation
input double   InpRangePercent          = 1.20;   // Max range (% of mid price) to count as consolidation
input double   InpBreakoutBufferPercent = 0.10;   // Breakout buffer (% above box high)
input color    InpBoxColor              = clrDeepSkyBlue;
input int      InpTransparency          = 80;     // 0=solid, 255=invisible
input bool     InpBoxInBackground       = true;  // Draw behind candles (true) or on top (false)

string BoxName()
{
   return "ConsolidationBox_" + EnumToString((ENUM_TIMEFRAMES)Period());
}

bool EnsureRectangle(const string name)
{
   if(ObjectFind(0, name) >= 0) return true;

   if(!ObjectCreate(0, name, OBJ_RECTANGLE, 0, 0, 0))
      return false;

   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, InpBoxInBackground);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   return true;
}

void PaintRectangle(const string name, datetime t1, double p1, datetime t2, double p2)
{
   // Ensure left point is older time
   if(t1 > t2)
   {
      datetime tmpT = t1; t1 = t2; t2 = tmpT;
      double   tmpP = p1; p1 = p2; p2 = tmpP;
   }

   color c = ColorToARGB(InpBoxColor, (uchar)InpTransparency);

   ObjectSetInteger(0, name, OBJPROP_COLOR, c);

   ObjectSetInteger(0, name, OBJPROP_TIME, 0, t1);
   ObjectSetDouble (0, name, OBJPROP_PRICE, 0, p1);

   ObjectSetInteger(0, name, OBJPROP_TIME, 1, t2);
   ObjectSetDouble (0, name, OBJPROP_PRICE, 1, p2);
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
                const int &spread[])
{
   // Need enough CLOSED bars: we use indexes >= 1
   int maxNeed = InpLookbackBars + InpMaxConsolBars + 5;
   if(rates_total < maxNeed) return rates_total;

   string name = BoxName();
   if(!EnsureRectangle(name)) return rates_total;

   // We search for the MOST RECENT consolidation that is followed by an UP breakout.
   // Array indexing: 0 = current (forming), 1 = last closed, 2 = previous closed, etc.
   int lookback = MathMin(InpLookbackBars, rates_total - (InpMaxConsolBars + 5));
   bool found = false;

   int bestEnd = -1;
   int bestLen = -1;
   double bestHH = 0.0, bestLL = 0.0;

   for(int end = 2; end <= lookback && !found; end++) // end = most recent bar inside the box
   {
      for(int L = InpMinConsolBars; L <= InpMaxConsolBars; L++)
      {
         int oldest = end + L - 1;
         if(oldest >= rates_total) break;

         // Compute box high/low across [end .. oldest]
         double hh = high[end];
         double ll = low[end];
         for(int i = end; i <= oldest; i++)
         {
            if(high[i] > hh) hh = high[i];
            if(low[i]  < ll) ll = low[i];
         }

         double mid = (hh + ll) * 0.5;
         if(mid <= 0.0) continue;

         double range = hh - ll;
         double maxRange = mid * (InpRangePercent / 100.0);

         if(range <= maxRange)
         {
            // Require an UP breakout on the bar immediately after the box (more recent bar = end-1)
            int b = end - 1;
            double buffer = hh * (InpBreakoutBufferPercent / 100.0);
            if(close[b] > (hh + buffer))
            {
               bestEnd = end;
               bestLen = L;
               bestHH = hh;
               bestLL = ll;
               found = true;
               break;
            }
         }
      }
   }

   if(found)
   {
      int oldest = bestEnd + bestLen - 1;
      // Rectangle corners:
      // left (oldest) time, right (most recent in box) time
      datetime t_left  = time[oldest];
      datetime t_right = time[bestEnd];

      // Set top/bottom prices
      PaintRectangle(name, t_left, bestHH, t_right, bestLL);
   }
   else
   {
      // If nothing found, hide it off-chart
      PaintRectangle(name, time[1], close[1], time[1], close[1]);
   }

   return rates_total;
}
