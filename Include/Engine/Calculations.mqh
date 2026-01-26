#pragma once
// Include/Engine/Calculations.mqh
// NOTE: math/algorithms only. No drawing, no object creation.

#include <Arrays/ArrayObj.mqh>

enum ENUM_BIAS_STATE { BIAS_UP=1, BIAS_DOWN=-1, BIAS_SIDEWAYS=0 };

struct SRZone
{
   double low;
   double high;
   ENUM_TIMEFRAMES tf;
   int touches;
   datetime last_touch;
   bool is_support;   // true=support, false=resistance
};

struct ConsolidationBox
{
   bool   active;
   double low;
   double high;
   datetime t_from;
   datetime t_to;
   int bars;
};

class CCalculations
{
private:
   string m_symbol;
   double PipSize() const
   {
      // Rough pip size: for 5/3 digits -> 10 points, else 1 point
      if(_Digits==3 || _Digits==5) return _Point*10.0;
      return _Point;
   }

   bool CopyRatesSafe(ENUM_TIMEFRAMES tf, int lookback, MqlRates &rates[])
   {
      ArrayResize(rates, 0);
      int copied = CopyRates(m_symbol, tf, 0, lookback, rates);
      if(copied <= 0) return false;
      ArraySetAsSeries(rates, true);
      return true;
   }

   bool IsPivotHigh(const MqlRates &r[], int i, int strength) const
   {
      double h = r[i].high;
      for(int k=1; k<=strength; k++)
      {
         if(r[i-k].high >= h) return false;
         if(r[i+k].high >  h) return false;
      }
      return true;
   }

   bool IsPivotLow(const MqlRates &r[], int i, int strength) const
   {
      double l = r[i].low;
      for(int k=1; k<=strength; k++)
      {
         if(r[i-k].low <= l) return false;
         if(r[i+k].low <  l) return false;
      }
      return true;
   }

   void SortDoubles(double &a[])
   {
      int n = ArraySize(a);
      for(int i=0;i<n-1;i++)
      {
         for(int j=i+1;j<n;j++)
            if(a[j] < a[i]) { double t=a[i]; a[i]=a[j]; a[j]=t; }
      }
   }

   void MergeLevelsToZones(const double &levels[], ENUM_TIMEFRAMES tf, bool is_support,
                           double merge_pips, SRZone &outZones[])
   {
      ArrayResize(outZones, 0);
      int n = ArraySize(levels);
      if(n<=0) return;

      double pip = PipSize();
      double merge = merge_pips * pip;

      // Copy & sort
      double tmp[];
      ArrayResize(tmp, n);
      for(int i=0;i<n;i++) tmp[i]=levels[i];
      SortDoubles(tmp);

      // Build clusters
      double z_low = tmp[0];
      double z_high = tmp[0];
      int touches = 1;

      for(int i=1;i<n;i++)
      {
         if(MathAbs(tmp[i] - z_high) <= merge)
         {
            z_high = tmp[i];
            touches++;
         }
         else
         {
            SRZone z;
            z.low = z_low - merge*0.5;
            z.high = z_high + merge*0.5;
            z.tf = tf;
            z.touches = touches;
            z.last_touch = 0;
            z.is_support = is_support;

            int sz = ArraySize(outZones);
            ArrayResize(outZones, sz+1);
            outZones[sz] = z;

            z_low = tmp[i];
            z_high = tmp[i];
            touches = 1;
         }
      }

      // last zone
      SRZone z;
      z.low = z_low - merge*0.5;
      z.high = z_high + merge*0.5;
      z.tf = tf;
      z.touches = touches;
      z.last_touch = 0;
      z.is_support = is_support;

      int sz = ArraySize(outZones);
      ArrayResize(outZones, sz+1);
      outZones[sz] = z;
   }

   double SMA_Close(ENUM_TIMEFRAMES tf, int period, int shift=0)
   {
      // Simple MA computed from rates to avoid iMA handle management.
      MqlRates r[];
      if(!CopyRatesSafe(tf, period + shift + 10, r)) return 0.0;
      int start = shift;
      int end = shift + period - 1;
      if(end >= ArraySize(r)) return 0.0;
      double sum=0.0;
      for(int i=start;i<=end;i++) sum += r[i].close;
      return sum / period;
   }

   double ATR(ENUM_TIMEFRAMES tf, int period, int shift=0)
   {
      MqlRates r[];
      if(!CopyRatesSafe(tf, period + shift + 2, r)) return 0.0;
      int need = shift + period + 1;
      if(ArraySize(r) < need) return 0.0;

      double sumTR=0.0;
      for(int i=shift; i<shift+period; i++)
      {
         double high = r[i].high;
         double low  = r[i].low;
         double prevClose = r[i+1].close;
         double tr = MathMax(high-low, MathMax(MathAbs(high-prevClose), MathAbs(low-prevClose)));
         sumTR += tr;
      }
      return sumTR / period;
   }

public:
   // Public state accessible by the App/Renderer
   ENUM_BIAS_STATE    Bias;
   double             ReboundScore;          // 0..100
   double             PullbackPct;           // W1 pullback %
   string             DipStatus;             // Falling/Stabilizing/Reversing
   string             VolumeStatus;          // Confirming/Not confirming
   ConsolidationBox   ConsBox;

   SRZone ZonesMN_Support[];
   SRZone ZonesMN_Resist[];
   SRZone ZonesW1_Support[];
   SRZone ZonesW1_Resist[];
   SRZone ZonesD1_Support[];
   SRZone ZonesD1_Resist[];

   CCalculations(): m_symbol(_Symbol)
   {
      Reset();
   }

   void SetSymbol(const string symbol){ m_symbol=symbol; }

   void Reset()
   {
      Bias = BIAS_SIDEWAYS;
      ReboundScore = 0.0;
      PullbackPct = 0.0;
      DipStatus = "N/A";
      VolumeStatus = "N/A";
      ConsBox.active=false; ConsBox.low=0; ConsBox.high=0; ConsBox.t_from=0; ConsBox.t_to=0; ConsBox.bars=0;

      ArrayResize(ZonesMN_Support,0); ArrayResize(ZonesMN_Resist,0);
      ArrayResize(ZonesW1_Support,0); ArrayResize(ZonesW1_Resist,0);
      ArrayResize(ZonesD1_Support,0); ArrayResize(ZonesD1_Resist,0);
   }

   void BuildZones(ENUM_TIMEFRAMES tf, int lookback, int pivotStrength, double mergePips,
                   SRZone &outSupport[], SRZone &outResist[])
   {
      MqlRates r[];
      if(!CopyRatesSafe(tf, lookback, r))
      {
         ArrayResize(outSupport,0);
         ArrayResize(outResist,0);
         return;
      }
      int n = ArraySize(r);
      if(n < (pivotStrength*2 + 10))
      {
         ArrayResize(outSupport,0);
         ArrayResize(outResist,0);
         return;
      }

      double supp_levels[];
      double res_levels[];
      ArrayResize(supp_levels, 0);
      ArrayResize(res_levels, 0);

      // skip newest few bars for stability: start at pivotStrength and end at n-pivotStrength-1
      for(int i=pivotStrength; i<=n-pivotStrength-1; i++)
      {
         if(IsPivotHigh(r, i, pivotStrength))
         {
            int sz = ArraySize(res_levels);
            ArrayResize(res_levels, sz+1);
            res_levels[sz]=r[i].high;
         }
         if(IsPivotLow(r, i, pivotStrength))
         {
            int sz = ArraySize(supp_levels);
            ArrayResize(supp_levels, sz+1);
            supp_levels[sz]=r[i].low;
         }
      }

      MergeLevelsToZones(supp_levels, tf, true,  mergePips, outSupport);
      MergeLevelsToZones(res_levels,  tf, false, mergePips, outResist);
   }

   ENUM_BIAS_STATE ComputeMonthlyBias(int lookbackMN, int maPeriodMN)
   {
      // Bias by MA + slope + basic HH/HL from pivots
      MqlRates r[];
      if(!CopyRatesSafe(PERIOD_MN1, MathMax(lookbackMN, maPeriodMN+20), r))
         return BIAS_SIDEWAYS;

      double ma0 = SMA_Close(PERIOD_MN1, maPeriodMN, 0);
      double ma3 = SMA_Close(PERIOD_MN1, maPeriodMN, 3);
      if(ma0==0 || ma3==0) return BIAS_SIDEWAYS;

      bool aboveMA = (r[0].close > ma0);
      bool slopeUp = (ma0 > ma3);

      // Pivot HH/HL check (very lightweight)
      double highs[], lows[];
      ArrayResize(highs,0); ArrayResize(lows,0);
      int strength=3;
      for(int i=strength; i<=ArraySize(r)-strength-1 && (ArraySize(highs)<10 || ArraySize(lows)<10); i++)
      {
         if(IsPivotHigh(r,i,strength))
         {
            int sz=ArraySize(highs); ArrayResize(highs,sz+1); highs[sz]=r[i].high;
         }
         if(IsPivotLow(r,i,strength))
         {
            int sz=ArraySize(lows); ArrayResize(lows,sz+1); lows[sz]=r[i].low;
         }
      }

      bool hhhl=false;
      if(ArraySize(highs)>=2 && ArraySize(lows)>=2)
         hhhl = (highs[0] > highs[1] && lows[0] > lows[1]);

      if(aboveMA && slopeUp && hhhl) return BIAS_UP;

      // Down bias mirror (optional)
      bool belowMA = (r[0].close < ma0);
      bool slopeDown = (ma0 < ma3);
      bool lllh=false;
      if(ArraySize(highs)>=2 && ArraySize(lows)>=2)
         lllh = (highs[0] < highs[1] && lows[0] < lows[1]);
      if(belowMA && slopeDown && lllh) return BIAS_DOWN;

      return BIAS_SIDEWAYS;
   }

   bool DetectWeeklyConsolidation(int minBars, double atrMult, int atrPeriod)
   {
      ConsBox.active=false;
      MqlRates r[];
      if(!CopyRatesSafe(PERIOD_W1, minBars + atrPeriod + 10, r)) return false;
      if(ArraySize(r) < minBars+2) return false;

      double hi=r[0].high, lo=r[0].low;
      datetime t_from=r[minBars-1].time;
      datetime t_to=r[0].time;
      for(int i=0;i<minBars;i++)
      {
         hi = MathMax(hi, r[i].high);
         lo = MathMin(lo, r[i].low);
      }

      double atr = ATR(PERIOD_W1, atrPeriod, 0);
      if(atr<=0) return false;

      if((hi-lo) <= (atrMult*atr))
      {
         ConsBox.active=true;
         ConsBox.high=hi;
         ConsBox.low=lo;
         ConsBox.t_from=t_from;
         ConsBox.t_to=t_to;
         ConsBox.bars=minBars;
         return true;
      }
      return false;
   }

   double ComputeWeeklyPullbackPct(int lookbackW1, int pivotStrength)
   {
      MqlRates r[];
      if(!CopyRatesSafe(PERIOD_W1, lookbackW1, r)) return 0.0;

      // Find latest pivot swing high (excluding bar 0 if it's still forming)
      int strength=pivotStrength;
      double swingHigh=0.0;
      for(int i=1+strength; i<=ArraySize(r)-strength-1; i++)
      {
         if(IsPivotHigh(r, i, strength))
         {
            swingHigh = r[i].high;
            break;
         }
      }
      if(swingHigh<=0) return 0.0;
      double cur = r[0].close;
      return (swingHigh - cur) / swingHigh * 100.0;
   }

   bool VolumeConfirming(int volMAPeriod, double spikeMult, bool useOBV)
   {
      // Simple: volume spike near support + rejection style candle (approximated)
      VolumeStatus="Not confirming";

      MqlRates r[];
      if(!CopyRatesSafe(PERIOD_W1, volMAPeriod + 10, r)) return false;
      if(ArraySize(r) < volMAPeriod+2) return false;

      // Volume MA
      double vma=0.0;
      for(int i=0;i<volMAPeriod;i++) vma += (double)r[i].tick_volume;
      vma /= volMAPeriod;

      bool spike = ((double)r[0].tick_volume > vma * spikeMult);
      bool bullishClose = (r[0].close > r[0].open);
      bool longLowerWick = ((r[0].open - r[0].low) > (r[0].high - r[0].close)); // crude

      if(spike && (bullishClose || longLowerWick))
      {
         VolumeStatus="Confirming";
         return true;
      }

      if(useOBV)
      {
         // Lightweight OBV slope over last 5 bars
         double obv=0, obv5=0;
         for(int i=1;i<=5;i++)
         {
            double dir = (r[i-1].close > r[i].close) ? 1 : (r[i-1].close < r[i].close ? -1 : 0);
            obv += dir * (double)r[i-1].tick_volume;
            if(i>=3) obv5 += dir * (double)r[i-1].tick_volume;
         }
         if(obv5 > 0)
         {
            VolumeStatus="Confirming";
            return true;
         }
      }

      return false;
   }

   string ComputeDipStatus(int atrPeriod)
   {
      // Very simplified knife vs stabilizing:
      MqlRates r[];
      if(!CopyRatesSafe(PERIOD_W1, 30, r)) return "N/A";
      double atr = ATR(PERIOD_W1, atrPeriod, 0);
      if(atr<=0) return "N/A";

      int ll=0;
      for(int i=0;i<5;i++)
      {
         if(r[i].low < r[i+1].low) ll++;
      }
      bool expanding = ((r[0].high - r[0].low) > 1.5*atr);

      if(ll>=3 || expanding) return "Falling";

      // stabilizing if last 3 ranges contracting
      double r0=r[0].high-r[0].low, r1=r[1].high-r[1].low, r2=r[2].high-r[2].low;
      if(r0 < r1 && r1 < r2) return "Stabilizing";

      // reversing if bullish engulf-ish
      bool bullish = (r[0].close > r[0].open);
      bool reclaim = (r[0].close > r[1].high);
      if(bullish && reclaim) return "Reversing";

      return "Stabilizing";
   }

   double DistanceToNearestSupport(double price, const SRZone &zones[])
   {
      double best = DBL_MAX;
      int n=ArraySize(zones);
      for(int i=0;i<n;i++)
      {
         // distance to zone if outside, else 0
         double d=0;
         if(price < zones[i].low) d = zones[i].low - price;
         else if(price > zones[i].high) d = price - zones[i].high;
         else d=0;
         if(d < best) best=d;
      }
      if(best==DBL_MAX) return 0;
      return best;
   }

   double ComputeReboundScore(double pullbackPct, double atrW1, double distToSupport, bool cons, bool volOk)
   {
      double score=0.0;

      // Pullback in range gives a base
      if(pullbackPct>=0.0) score += 10.0;
      if(pullbackPct>=5.0) score += 10.0;

      // Near support
      if(atrW1>0 && distToSupport <= 0.5*atrW1) score += 25.0;

      // Consolidation
      if(cons) score += 20.0;

      // Volume
      if(volOk) score += 20.0;

      // Cap
      if(score>100.0) score=100.0;
      return score;
   }

   void UpdateAll(int lookMN, int lookW1, int lookD1, int pivotStrength, double mergePips,
                  int maMN, int atrPeriod, int consBars, double consAtrMult,
                  double pbMin, double pbMax, int volMAPeriod, double volSpikeMult, bool useOBV)
   {
      Reset();

      Bias = ComputeMonthlyBias(lookMN, maMN);

      // Zones
      BuildZones(PERIOD_MN1, lookMN, pivotStrength, mergePips, ZonesMN_Support, ZonesMN_Resist);
      BuildZones(PERIOD_W1,  lookW1, pivotStrength, mergePips, ZonesW1_Support, ZonesW1_Resist);
      BuildZones(PERIOD_D1,  lookD1, pivotStrength, mergePips, ZonesD1_Support, ZonesD1_Resist);

      // Weekly details
      PullbackPct = ComputeWeeklyPullbackPct(lookW1, pivotStrength);

      bool cons = DetectWeeklyConsolidation(consBars, consAtrMult, atrPeriod);
      bool volOk = VolumeConfirming(volMAPeriod, volSpikeMult, useOBV);

      DipStatus = ComputeDipStatus(atrPeriod);

      // score only meaningful in MN uptrend
      if(Bias==BIAS_UP && PullbackPct>=pbMin && PullbackPct<=pbMax)
      {
         MqlRates w1[];
         if(CopyRatesSafe(PERIOD_W1, 10, w1))
         {
            double atrW1 = ATR(PERIOD_W1, atrPeriod, 0);
            double price = w1[0].close;

            // Prefer W1 support; fallback to MN1 support
            double dist = DistanceToNearestSupport(price, ZonesW1_Support);
            if(dist<=0 && ArraySize(ZonesMN_Support)>0) dist = DistanceToNearestSupport(price, ZonesMN_Support);

            ReboundScore = ComputeReboundScore(PullbackPct, atrW1, dist, cons, volOk);

            // Penalize if still falling
            if(DipStatus=="Falling")
               ReboundScore = MathMax(0.0, ReboundScore - 25.0);
         }
      }
      else
      {
         ReboundScore = 0.0;
      }
   }
};
