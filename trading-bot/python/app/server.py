from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel
from typing import Optional, List

app = FastAPI()

API_KEY = "change-me"

class Payload(BaseModel):
    symbol: str
    timeframe: str
    point: float
    digits: int
    lookback: int = 30
    max_range_points: float = 200.0
    # candles_csv lines: "t,open,high,low,close" one per line (t is unix seconds)
    candles_csv: str

@app.post("/box")
def box(p: Payload, x_api_key: str = Header(default="")):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    lines = [ln.strip() for ln in p.candles_csv.split("\n") if ln.strip()]
    if len(lines) < 5:
        return {"state": "NO_DATA"}

    highs = []
    lows = []
    # use last N completed candles (we assume MT5 sends newest first; we’ll just read all)
    for ln in lines[:p.lookback]:
        parts = ln.split(",")
        if len(parts) != 5:
            continue
        try:
            high = float(parts[2])
            low  = float(parts[3])
        except:
            continue
        highs.append(high)
        lows.append(low)

    if not highs or not lows:
        return {"state": "BAD_DATA"}

    box_high = max(highs)
    box_low  = min(lows)
    rng_points = (box_high - box_low) / p.point if p.point > 0 else 999999

    state = "CONSOLIDATING" if rng_points <= p.max_range_points else "NO"

    return {
        "state": state,
        "box_high": round(box_high, p.digits),
        "box_low": round(box_low, p.digits),
        "range_points": round(rng_points, 1),
        "lookback_used": min(len(highs), p.lookback)
    }
