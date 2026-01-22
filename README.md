# Trading Setup: False Breakout & Range Rotation

## 1. Context
Market rejects higher prices (Resistance) and rotates back into the previous balance area.
* **The Trap:** Price breaks Resistance, fails to hold, and falls back inside ("Bull Trap").
* **The Destination:** Price seeks the lower boundary (Support).

---

## 2. Execution Plan

### 🎯 Strategy: Buy the Bounce
Capitalize on the return to value. Buy at Support, anticipating a move back to Resistance.

| Component | Action | Logic |
| :--- | :--- | :--- |
| **🟢 ENTRY** | **At Support** | Wait for reaction (Pinbar/Green candle). |
| **🔴 STOP LOSS** | **Below Support** | If Support breaks, the thesis is invalid. |
| **🏁 TAKE PROFIT** | **Below Resistance** | Exit before sellers step in again. |

---

## 3. Visualization

```mermaid
graph TD
    %% Nodes
    RES[("🛑 Resistance Zone")]
    SUP[("✅ Support Zone")]
    
    %% Flow
    Start(Price in Range) -->|Breakout| Fake(False Breakout / Bull Trap)
    Fake -->|Rejection| Return(Falls back into Range)
    Return -->|Drops to| BuyZone{BUY ZONE}
    
    %% Action
    BuyZone -->|🟢 Entry: Long| Bounce(Price Bounces)
    Bounce -->|Profit Run| TP(🏁 TP: Target Resistance)

    %% Styling
    style RES fill:#ff9999,stroke:#333
    style SUP fill:#99ff99,stroke:#333
    style BuyZone fill:#ccffcc,stroke:#090,stroke-width:4px
    style Fake fill:#ffcccc,stroke:#f00,stroke-dasharray: 5 5