/* global React */

// 17 outline icons — 24px grid, 1.5px stroke, round caps. Active = ember.
function Icon({ name, size = 24, color = "currentColor", strokeWidth = 1.5, style }) {
  const common = {
    width: size, height: size, viewBox: "0 0 24 24",
    fill: "none", stroke: color, strokeWidth,
    strokeLinecap: "round", strokeLinejoin: "round",
    style: { filter: "drop-shadow(0 1px 6px rgba(0,0,0,0.55))", ...style },
  };
  switch (name) {
    case "missile":
      return <svg {...common}><path d="M12 2 L14.5 7 L14.5 17.5 L16.5 21 L7.5 21 L9.5 17.5 L9.5 7 Z"/><line x1="12" y1="2" x2="12" y2="7"/></svg>;
    case "bomb":
      return <svg {...common}><circle cx="12" cy="14" r="6"/><path d="M12 8 L12 4"/><path d="M10 4 L14 4"/><path d="M14 4 L17 1"/></svg>;
    case "laser":
      return <svg {...common}><line x1="3" y1="12" x2="15" y2="12"/><path d="M15 9 L21 12 L15 15 Z"/></svg>;
    case "shield":
      return <svg {...common}><path d="M12 3 L4 6 L4 12 C4 16.5 7.5 20 12 21 C16.5 20 20 16.5 20 12 L20 6 Z"/></svg>;
    case "ring":
      return <svg {...common}><circle cx="12" cy="12" r="7"/></svg>;
    case "wave":
      return <svg {...common}><path d="M3 14 C 6 9, 9 9, 12 14 S 18 19, 21 14"/></svg>;
    case "multiplier":
      return <svg {...common}><line x1="5" y1="5" x2="19" y2="19"/><line x1="19" y1="5" x2="5" y2="19"/></svg>;
    case "speed":
      return <svg {...common}><path d="M3 17 L9 11 L13 15 L21 7"/><path d="M21 7 L21 12 M21 7 L16 7"/></svg>;
    case "alt":
      return <svg {...common}><path d="M4 19 L12 4 L20 19 Z"/><line x1="4" y1="19" x2="20" y2="19"/></svg>;
    case "hdg":
      return <svg {...common}><circle cx="12" cy="12" r="9"/><line x1="12" y1="3" x2="12" y2="6"/><line x1="12" y1="18" x2="12" y2="21"/><line x1="3" y1="12" x2="6" y2="12"/><line x1="18" y1="12" x2="21" y2="12"/></svg>;
    case "pause":
      return <svg {...common}><line x1="9" y1="5" x2="9" y2="19"/><line x1="15" y1="5" x2="15" y2="19"/></svg>;
    case "play":
      return <svg {...common}><path d="M7 4 L20 12 L7 20 Z"/></svg>;
    case "settings":
      return <svg {...common}><circle cx="12" cy="12" r="3"/><path d="M12 2 L12 5 M12 19 L12 22 M2 12 L5 12 M19 12 L22 12 M5 5 L7 7 M17 17 L19 19 M5 19 L7 17 M17 7 L19 5"/></svg>;
    case "back":
      return <svg {...common}><path d="M14 6 L8 12 L14 18"/></svg>;
    case "lock":
      return <svg {...common}><rect x="6" y="11" width="12" height="9" rx="1"/><path d="M9 11 L9 7 C9 5 10.5 4 12 4 S15 5 15 7 L15 11"/></svg>;
    case "trophy":
      return <svg {...common}><path d="M7 4 L17 4 L17 9 C17 12 15 14 12 14 C9 14 7 12 7 9 Z"/><path d="M7 6 L4 6 L4 8 C4 10 5 11 7 11"/><path d="M17 6 L20 6 L20 8 C20 10 19 11 17 11"/><line x1="12" y1="14" x2="12" y2="18"/><line x1="8" y1="20" x2="16" y2="20"/><line x1="9" y1="18" x2="15" y2="18"/></svg>;
    case "chevron-r":
      return <svg {...common}><path d="M10 6 L16 12 L10 18"/></svg>;
    default:
      return null;
  }
}

window.Icon = Icon;
