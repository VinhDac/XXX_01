from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

app = FastAPI()
API_KEY = "change-me"

class BoxReq(BaseModel):
    symbol: str
    timeframe: str
    mid: float
    point: float
    digits: int
    box_points: int
    box_minutes: int

@app.get("/health")
def health():
    return {"ok": True}

@app.post("/box")
def box(req: BoxReq, x_api_key: str = Header(default="")):
    if x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Unauthorized")

    box_high = req.mid + req.box_points * req.point
    box_low  = req.mid - req.box_points * req.point

    return {
        "state": "CONSOLIDATING",
        "box_high": round(box_high, req.digits),
        "box_low": round(box_low, req.digits),
        "reason": "step1_demo_box"
    }
