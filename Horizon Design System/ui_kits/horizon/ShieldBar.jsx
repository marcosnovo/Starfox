/* global React */
function ShieldBar({ value = 0.55, charged = false, width = 220 }) {
  const critical = value < 0.30;
  const fill = charged ? "#7adfd0" : (critical ? "#ff5566" : "#fff5e8");
  return (
    <div>
      <div style={{
        font: '500 11px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
        color: "rgba(255,245,232,0.65)", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        marginBottom: 8,
      }}>Shield</div>
      <div style={{
        width, height: 12,
        border: "1.5px solid rgba(255,245,232,0.85)", borderRadius: 1,
        padding: 2, boxSizing: "border-box",
      }}>
        <div style={{
          width: `${Math.max(0, Math.min(1, value)) * 100}%`, height: "100%",
          background: fill,
          transition: "width 220ms cubic-bezier(0.2, 0.7, 0.2, 1), background-color 160ms",
        }}/>
      </div>
    </div>
  );
}
window.ShieldBar = ShieldBar;
