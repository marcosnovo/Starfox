/* global React */
const buttonBase = {
  font: '500 12px "JetBrains Mono"',
  letterSpacing: "0.22em", textTransform: "uppercase",
  cursor: "pointer", borderRadius: 2,
  transition: "transform 160ms cubic-bezier(0.2, 0.7, 0.2, 1), border-color 160ms, background 160ms",
};
function PrimaryButton({ children, onClick, style }) {
  return (
    <button onClick={onClick} style={{
      ...buttonBase,
      background: "#fff5e8", color: "#0a0612",
      border: "none", padding: "16px 32px",
      ...style,
    }}
    onMouseDown={e => e.currentTarget.style.transform = "translateY(1px)"}
    onMouseUp={e => e.currentTarget.style.transform = ""}
    onMouseLeave={e => e.currentTarget.style.transform = ""}>
      {children}
    </button>
  );
}
function GhostButton({ children, onClick, leading, style }) {
  return (
    <button onClick={onClick} style={{
      ...buttonBase,
      background: "transparent", color: "#fff5e8",
      border: "1px solid rgba(255,245,232,0.4)",
      padding: "13px 26px",
      display: "inline-flex", alignItems: "center", gap: 10,
      ...style,
    }}
    onMouseEnter={e => e.currentTarget.style.borderColor = "rgba(255,245,232,0.85)"}
    onMouseLeave={e => { e.currentTarget.style.borderColor = "rgba(255,245,232,0.4)"; e.currentTarget.style.transform = ""; }}
    onMouseDown={e => e.currentTarget.style.transform = "translateY(1px)"}
    onMouseUp={e => e.currentTarget.style.transform = ""}>
      {leading}{children}
    </button>
  );
}
window.PrimaryButton = PrimaryButton;
window.GhostButton = GhostButton;
