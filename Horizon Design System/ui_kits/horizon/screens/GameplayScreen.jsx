/* global React, Reticle, ShieldBar, WeaponsRack, Icon */

function GameplayScreen({ onPause, compact = false }) {
  const [score, setScore] = React.useState(2450);
  const [shield, setShield] = React.useState(0.55);
  const [mult, setMult] = React.useState(2.0);

  React.useEffect(() => {
    const t = setInterval(() => {
      setScore(s => s + Math.floor(Math.random() * 30));
      setShield(s => Math.max(0.18, Math.min(1, s + (Math.random() - 0.55) * 0.04)));
    }, 600);
    return () => clearInterval(t);
  }, []);

  const sizeScale = compact ? 0.78 : 1;
  const shadow = "0 1px 8px rgba(0,0,0,0.5)";
  const labelStyle = {
    font: '500 11px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
    color: "rgba(255,245,232,0.65)", textShadow: shadow,
  };

  return (
    <div style={{ position: "absolute", inset: 0 }}>
      {/* TL: Score */}
      <div style={{ position: "absolute", top: 22, left: 26 }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          <div>
            <div style={labelStyle}>Score</div>
            <div style={{
              font: `300 ${38 * sizeScale}px/1 "JetBrains Mono"`, letterSpacing: "-0.02em",
              color: "#fff5e8", marginTop: 4, textShadow: shadow,
            }}>{score.toLocaleString()}</div>
          </div>
          <div>
            <div style={labelStyle}>Rings</div>
            <div style={{
              font: `300 ${28 * sizeScale}px/1 "JetBrains Mono"`,
              color: "#fff5e8", marginTop: 4, textShadow: shadow,
            }}>23</div>
          </div>
        </div>
      </div>

      {/* TR: Wave / Multiplier */}
      <div style={{ position: "absolute", top: 22, right: 26, textAlign: "right" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16, alignItems: "flex-end" }}>
          <div>
            <div style={labelStyle}>Wave</div>
            <div style={{
              font: `300 ${38 * sizeScale}px/1 "JetBrains Mono"`, letterSpacing: "-0.02em",
              color: "#fff5e8", marginTop: 4, textShadow: shadow,
            }}>03</div>
          </div>
          <div>
            <div style={labelStyle}>Multiplier</div>
            <div style={{
              font: `300 ${28 * sizeScale}px/1 "JetBrains Mono"`,
              color: mult >= 2 ? "#ffb347" : "#fff5e8",
              marginTop: 4, textShadow: shadow,
            }}>×{mult.toFixed(1)}</div>
          </div>
        </div>
      </div>

      {/* Center reticle */}
      <div style={{ position: "absolute", left: "50%", top: "47%", transform: "translate(-50%, -50%)" }}>
        <Reticle size={72 * sizeScale}/>
      </div>

      {/* BL: Shield */}
      <div style={{ position: "absolute", left: 26, bottom: 22 }}>
        <ShieldBar value={shield} width={200 * sizeScale}/>
      </div>

      {/* BR: Weapons */}
      <div style={{ position: "absolute", right: 26, bottom: 22 }}>
        <WeaponsRack active={1}/>
      </div>

      {/* Pause button (top center, subtle) */}
      <button onClick={onPause} style={{
        all: "unset", cursor: "pointer",
        position: "absolute", top: 26, left: "50%", transform: "translateX(-50%)",
        padding: "6px 10px",
        font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
        color: "rgba(255,245,232,0.65)", textShadow: shadow,
        display: "inline-flex", alignItems: "center", gap: 6,
      }}>
        <Icon name="pause" size={14} color="rgba(255,245,232,0.65)" style={{ filter: "none" }}/>
        Pause
      </button>
    </div>
  );
}
window.GameplayScreen = GameplayScreen;
