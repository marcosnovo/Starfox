/* global React */
function Reticle({ size = 72, locked = false }) {
  const color = locked ? "#ff6a1a" : "#fff5e8";
  const stroke = locked ? 1.8 : 1.5;
  return (
    <svg width={size} height={size * 0.55} viewBox="0 0 100 55"
         style={{ filter: "drop-shadow(0 1px 6px rgba(0,0,0,0.55))", overflow: "visible" }}>
      <path d="M 22 8 L 12 8 L 12 47 L 22 47" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="square"/>
      <path d="M 78 8 L 88 8 L 88 47 L 78 47" fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="square"/>
      <line x1="46" y1="27.5" x2="42" y2="27.5" stroke={color} strokeWidth={1.4}/>
      <line x1="54" y1="27.5" x2="58" y2="27.5" stroke={color} strokeWidth={1.4}/>
      <line x1="50" y1="23.5" x2="50" y2="20" stroke={color} strokeWidth={1.4}/>
      <line x1="50" y1="31.5" x2="50" y2="35" stroke={color} strokeWidth={1.4}/>
      <circle cx="50" cy="27.5" r="1.2" fill={color}/>
    </svg>
  );
}
window.Reticle = Reticle;
