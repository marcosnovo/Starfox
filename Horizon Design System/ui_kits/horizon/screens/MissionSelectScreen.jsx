/* global React, MissionCard, GhostButton, PrimaryButton, Icon */
function MissionSelectScreen({ onBack, onLaunch }) {
  const missions = [
    { wave: "01", name: "First Light",  subtitle: "An easy climb. Find the rhythm.",  status: "completed", stars: 3 },
    { wave: "02", name: "The Pass",     subtitle: "The pass narrows. Hold steady.",  status: "completed", stars: 2 },
    { wave: "03", name: "Caldera",      subtitle: "Volcanic ridges. Watch the lock-on.", status: "available" },
    { wave: "04", name: "Long Night",   subtitle: "Clear Caldera to unlock.",         status: "locked" },
  ];
  return (
    <div style={{ position: "absolute", inset: 0,
      background: "rgba(10,6,18,0.55)", backdropFilter: "blur(2px)" }}>
      <HudMask scrim={0.4}/>
      <div style={{ position: "absolute", inset: 0, padding: 40, color: "#fff5e8",
        display: "flex", flexDirection: "column" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{
              font: '500 10px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
              color: "rgba(255,245,232,0.65)", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
            }}>Select wave</div>
            <div style={{
              font: '300 40px "Inter Tight"', letterSpacing: "-0.02em",
              color: "#fff5e8", marginTop: 6, textShadow: "0 1px 12px rgba(0,0,0,0.5)",
            }}>Long flight.</div>
          </div>
          <GhostButton onClick={onBack} leading={<Icon name="back" size={14} color="#fff5e8" style={{ filter:"none" }}/>}>Back</GhostButton>
        </div>

        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 14, marginTop: 32 }}>
          {missions.map(m => (
            <MissionCard key={m.wave} {...m} onClick={() => onLaunch(m)}/>
          ))}
        </div>

        <div style={{ marginTop: "auto", display: "flex", justifyContent: "space-between", alignItems: "center",
          background: "rgba(10,6,18,0.55)", backdropFilter: "blur(14px)",
          border: "1px solid rgba(255,245,232,0.12)", borderRadius: 4,
          padding: "16px 20px" }}>
          <div style={{ display: "flex", gap: 36 }}>
            <div>
              <div style={{ font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase", color: "rgba(255,245,232,0.65)" }}>Best</div>
              <div style={{ font: '300 22px "JetBrains Mono"', color: "#fff5e8", marginTop: 4 }}>14,820</div>
            </div>
            <div>
              <div style={{ font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase", color: "rgba(255,245,232,0.65)" }}>Rings</div>
              <div style={{ font: '300 22px "JetBrains Mono"', color: "#fff5e8", marginTop: 4 }}>1,248</div>
            </div>
            <div>
              <div style={{ font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase", color: "rgba(255,245,232,0.65)" }}>Runs</div>
              <div style={{ font: '300 22px "JetBrains Mono"', color: "#fff5e8", marginTop: 4 }}>47</div>
            </div>
          </div>
          <PrimaryButton onClick={() => onLaunch(missions[2])}>Launch</PrimaryButton>
        </div>
      </div>
    </div>
  );
}
window.MissionSelectScreen = MissionSelectScreen;
