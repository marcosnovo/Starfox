/* global React */
function BrandMark({ size = 1, withTagline = true }) {
  const wordSize = 64 * size;
  const lineWidth = 360 * size;
  const tagSize = 22 * size;
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 * size }}>
      <div style={{ position: "relative", padding: `${14 * size}px 0` }}>
        <div style={{ width: lineWidth, height: 1, background: "#fff5e8", opacity: 0.85 }}/>
        <div style={{
          position: "absolute",
          left: "50%", bottom: 38 * size,
          transform: "translateX(-50%)",
          width: 64 * size, height: 32 * size,
          border: "1.5px solid #fff5e8", borderBottom: 0,
          borderRadius: `${32 * size}px ${32 * size}px 0 0`,
        }}/>
        <div style={{
          font: `200 ${wordSize}px "Inter Tight"`,
          letterSpacing: 14 * size,
          color: "#fff5e8",
          marginTop: 14 * size,
          textShadow: "0 1px 12px rgba(0,0,0,0.5)",
          textAlign: "center",
          paddingLeft: 14 * size,  // optical centering for tracked text
        }}>HORIZON</div>
      </div>
      {withTagline && (
        <div style={{
          font: `300 italic ${tagSize}px "Inter Tight"`,
          color: "#f5d8a8",
          textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        }}>Chase the light.</div>
      )}
    </div>
  );
}
window.BrandMark = BrandMark;
