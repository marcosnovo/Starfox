/* global React, BrandMark */
function CoverScreen({ onContinue }) {
  return (
    <div style={{ position: "absolute", inset: 0, padding: 56, color: "#fff5e8" }} onClick={onContinue}>
      <HudMask scrim={0.25}/>
      <div style={{ position: "absolute", inset: 0,
        background: "linear-gradient(180deg, rgba(10,6,18,0.45) 0%, rgba(10,6,18,0) 35%, rgba(10,6,18,0) 60%, rgba(10,6,18,0.55) 100%)" }}/>
      <div style={{ position: "relative" }}>
        <div style={{
          font: '500 11px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
          color: "#f5d8a8", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        }}>An arcade flight game · 2026</div>
        <h1 style={{
          font: '200 128px/0.95 "Inter Tight"', letterSpacing: "-0.04em",
          color: "#fff5e8", margin: "20px 0 8px",
          textShadow: "0 1px 16px rgba(0,0,0,0.45)",
        }}>Horizon</h1>
        <div style={{
          font: '300 italic 22px "Inter Tight"', color: "#f5d8a8",
          textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        }}>Chase the light.</div>
      </div>
      <div style={{ position: "absolute", right: 56, bottom: 56, textAlign: "right",
        font: '500 10px/1.6 "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
        color: "rgba(255,245,232,0.65)", textShadow: "0 1px 8px rgba(0,0,0,0.5)" }}>
        <div style={{ color: "#fff5e8" }}>Design system</div>
        <div>v1.0 · Apr 2026</div>
        <div style={{ marginTop: 14, color: "rgba(255,245,232,0.45)" }}>Click anywhere →</div>
      </div>
    </div>
  );
}
window.CoverScreen = CoverScreen;
