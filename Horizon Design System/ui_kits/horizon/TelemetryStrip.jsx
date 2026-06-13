/* global React */
function TelemetryStrip({ alt = "12,840 ft", spd = "0.82 M", hdg = "287°" }) {
  const k = { color: "rgba(255,245,232,0.55)", marginRight: 6 };
  return (
    <div style={{
      fontFamily: '"JetBrains Mono"', fontSize: 13, letterSpacing: "0.18em",
      color: "rgba(255,245,232,0.85)",
      display: "flex", gap: 24,
      padding: "8px 18px",
      background: "rgba(10,6,18,0.45)",
      border: "1px solid rgba(255,245,232,0.12)",
      borderRadius: 2,
      textShadow: "0 1px 8px rgba(0,0,0,0.5)",
      width: "fit-content",
    }}>
      <div><span style={k}>ALT</span>{alt}</div>
      <div><span style={k}>SPD</span>{spd}</div>
      <div><span style={k}>HDG</span>{hdg}</div>
    </div>
  );
}
window.TelemetryStrip = TelemetryStrip;
