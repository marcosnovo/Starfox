/* global React, BrandMark, PrimaryButton, GhostButton */
function TitleScreen({ onBegin, onMissions, onSettings }) {
  return (
    <div style={{ position: "absolute", inset: 0, color: "#fff5e8" }}>
      <HudMask scrim={0.3}/>
      <div style={{ position: "absolute", inset: 0,
        background: "linear-gradient(180deg, rgba(10,6,18,0.45) 0%, rgba(10,6,18,0) 35%, rgba(10,6,18,0) 60%, rgba(10,6,18,0.55) 100%)" }}/>
      <div style={{ position: "relative", height: "100%",
        display: "flex", flexDirection: "column", alignItems: "center",
        paddingTop: 68, paddingBottom: 56 }}>
        <div style={{
          font: '500 11px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
          color: "#f5d8a8", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        }}>An arcade flight game</div>
        <div style={{ flex: 1, display: "flex", alignItems: "center" }}>
          <BrandMark size={1.1}/>
        </div>
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 14 }}>
          <PrimaryButton onClick={onBegin}>Begin</PrimaryButton>
          <div style={{ display: "flex", gap: 12 }}>
            <GhostButton onClick={onMissions}>Missions</GhostButton>
            <GhostButton onClick={onSettings}>Settings</GhostButton>
          </div>
        </div>
      </div>
    </div>
  );
}
window.TitleScreen = TitleScreen;
