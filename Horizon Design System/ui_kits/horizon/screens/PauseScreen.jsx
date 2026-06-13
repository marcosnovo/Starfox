/* global React, GameplayScreen, PrimaryButton, GhostButton, TelemetryStrip */
function PauseScreen({ onResume, onQuit }) {
  return (
    <div style={{ position: "absolute", inset: 0 }}>
      <GameplayScreen compact={true}/>
      <div style={{ position: "absolute", inset: 0,
        background: "rgba(10,6,18,0.55)",
        backdropFilter: "blur(6px)", WebkitBackdropFilter: "blur(6px)",
      }}/>
      <div style={{ position: "absolute", inset: 0,
        display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
        gap: 28, color: "#fff5e8", padding: 40 }}>
        <div style={{
          font: '500 11px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
          color: "#f5d8a8", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        }}>Paused</div>
        <div style={{
          font: '200 56px "Inter Tight"', letterSpacing: "-0.03em", color: "#fff5e8",
          textShadow: "0 1px 16px rgba(0,0,0,0.5)", whiteSpace: "nowrap",
        }}>Catch your breath.</div>
        <div style={{ display: "flex", gap: 14, marginTop: 8 }}>
          <PrimaryButton onClick={onResume}>Resume</PrimaryButton>
          <GhostButton onClick={onQuit}>Quit run</GhostButton>
        </div>
        <div style={{ marginTop: 24 }}>
          <TelemetryStrip/>
        </div>
      </div>
    </div>
  );
}
window.PauseScreen = PauseScreen;
