/* global React */
// Hides the four corner HUD labels baked into starfox-bg.png on non-gameplay screens.
// Uses dark soft-edged corner pads, plus an overall slight scrim.
function HudMask({ scrim = 0.35 }) {
  const corner = (pos) => ({
    position: "absolute",
    width: 280, height: 90,
    background: "radial-gradient(ellipse at center, rgba(10,6,18,0.92) 0%, rgba(10,6,18,0.7) 45%, rgba(10,6,18,0) 75%)",
    pointerEvents: "none",
    ...pos,
  });
  return (
    <div style={{ position: "absolute", inset: 0, pointerEvents: "none" }}>
      <div style={{ position: "absolute", inset: 0, background: `rgba(10,6,18,${scrim})` }}/>
      <div style={corner({ top: -18, left: -40 })}/>
      <div style={corner({ top: -18, right: -40 })}/>
      <div style={corner({ bottom: -18, left: -40 })}/>
      <div style={corner({ bottom: -18, right: -40 })}/>
    </div>
  );
}
window.HudMask = HudMask;
