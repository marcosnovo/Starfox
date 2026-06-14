/* global React, PrimaryButton, GhostButton, Icon */
function ResultsScreen({ onAgain, onMissions }) {
  const stats = [
    { k: "Score",    v: "12,450" },
    { k: "Rings",    v: "84"     },
    { k: "Best ×",   v: "×4.0"   },
    { k: "Duration", v: "3:42"   },
  ];
  return (
    <div style={{ position: "absolute", inset: 0,
      background: "rgba(10,6,18,0.55)", backdropFilter: "blur(2px)" }}>
      <HudMask scrim={0.4}/>
      <div style={{ position: "absolute", inset: 0, padding: 40, color: "#fff5e8",
        display: "flex", flexDirection: "column", gap: 20 }}>
        <div>
          <div style={{
            font: '500 10px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
            color: "rgba(255,245,232,0.65)",
          }}>Run complete · Wave 03</div>
          <div style={{
            font: '200 56px "Inter Tight"', letterSpacing: "-0.03em",
            color: "#fff5e8", marginTop: 6, textShadow: "0 1px 12px rgba(0,0,0,0.5)",
          }}>Caldera, cleared.</div>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14 }}>
          {stats.map(s => (
            <div key={s.k} style={{
              background: "rgba(10,6,18,0.55)", backdropFilter: "blur(14px)",
              border: "1px solid rgba(255,245,232,0.12)", borderRadius: 4,
              padding: 18,
            }}>
              <div style={{ font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase", color: "rgba(255,245,232,0.65)" }}>{s.k}</div>
              <div style={{ font: '300 36px "JetBrains Mono"', letterSpacing: "-0.02em", color: "#fff5e8", marginTop: 8 }}>{s.v}</div>
            </div>
          ))}
        </div>

        <div style={{
          background: "rgba(10,6,18,0.55)", backdropFilter: "blur(14px)",
          border: "1px solid rgba(255,179,71,0.4)", borderRadius: 4,
          padding: "18px 20px",
          display: "flex", alignItems: "center", justifyContent: "space-between", gap: 18,
        }}>
          <div style={{ display: "flex", gap: 16, alignItems: "center" }}>
            <Icon name="trophy" size={28} color="#ffb347" style={{ filter: "none" }}/>
            <div>
              <div style={{ font: '500 10px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase", color: "#ffb347" }}>New record</div>
              <div style={{ font: '300 22px "Inter Tight"', color: "#fff5e8", marginTop: 4 }}>Longest chain on Caldera</div>
            </div>
          </div>
          <div style={{ font: '300 28px "JetBrains Mono"', letterSpacing: "-0.02em", color: "#ffb347" }}>+2,400</div>
        </div>

        <div style={{ marginTop: "auto", display: "flex", gap: 12 }}>
          <PrimaryButton onClick={onAgain}>Fly again</PrimaryButton>
          <GhostButton onClick={onMissions}>Mission select</GhostButton>
          <GhostButton>Leaderboard</GhostButton>
        </div>
      </div>
    </div>
  );
}
window.ResultsScreen = ResultsScreen;
