/* global React */
function Panel({ children, style, hi = false }) {
  return (
    <div style={{
      background: hi ? "rgba(10,6,18,0.6)" : "rgba(10,6,18,0.55)",
      backdropFilter: "blur(14px)",
      WebkitBackdropFilter: "blur(14px)",
      border: "1px solid rgba(255,245,232,0.12)",
      borderRadius: 4,
      padding: 24,
      color: "#fff5e8",
      ...style,
    }}>{children}</div>
  );
}
window.Panel = Panel;
