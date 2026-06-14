/* global React, Icon */
function MissionCard({ wave, name, subtitle, status = "available", stars = 0, onClick }) {
  const isLocked = status === "locked";
  const isCompleted = status === "completed";
  return (
    <button onClick={isLocked ? undefined : onClick} style={{
      all: "unset",
      boxSizing: "border-box",
      cursor: isLocked ? "not-allowed" : "pointer",
      minWidth: 180, height: 180,
      borderRadius: 4,
      background: "rgba(10,6,18,0.55)",
      backdropFilter: "blur(14px)",
      WebkitBackdropFilter: "blur(14px)",
      border: `1px solid ${isCompleted ? "rgba(255,179,71,0.5)" : "rgba(255,245,232,0.12)"}`,
      padding: 18,
      display: "flex", flexDirection: "column", justifyContent: "space-between",
      opacity: isLocked ? 0.45 : 1,
      transition: "border-color 160ms, transform 160ms cubic-bezier(0.2, 0.7, 0.2, 1)",
    }}
    onMouseEnter={e => { if (!isLocked && !isCompleted) e.currentTarget.style.borderColor = "rgba(255,245,232,0.4)"; }}
    onMouseLeave={e => { if (!isLocked && !isCompleted) e.currentTarget.style.borderColor = "rgba(255,245,232,0.12)"; }}>
      <div>
        <div style={{
          font: '500 10px "JetBrains Mono"', letterSpacing: "0.32em", textTransform: "uppercase",
          color: "rgba(255,245,232,0.65)",
        }}>Wave {wave}</div>
        <div style={{
          font: '300 22px/1.15 "Inter Tight"', letterSpacing: "-0.01em",
          color: "#fff5e8", marginTop: 6,
        }}>{name}</div>
        <div style={{
          font: '400 12px/1.4 "Inter Tight"',
          color: "rgba(255,245,232,0.65)", marginTop: 4,
        }}>{subtitle}</div>
      </div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <span style={{
          font: '500 10px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
          color: isCompleted ? "#ffb347" : "rgba(255,245,232,0.65)",
        }}>{status}</span>
        {isLocked ? (
          <Icon name="lock" size={20} color="rgba(255,245,232,0.65)" style={{ filter: "none" }}/>
        ) : isCompleted ? (
          <div style={{ display: "flex", gap: 5 }}>
            {[0,1,2].map(i => (
              <div key={i} style={{
                width: 7, height: 7, borderRadius: "50%",
                border: "1px solid rgba(255,179,71,0.7)",
                background: i < stars ? "#ffb347" : "transparent",
                borderColor: i < stars ? "#ffb347" : "rgba(255,179,71,0.7)",
              }}/>
            ))}
          </div>
        ) : (
          <Icon name="chevron-r" size={20} color="#fff5e8" style={{ filter: "none" }}/>
        )}
      </div>
    </button>
  );
}
window.MissionCard = MissionCard;
