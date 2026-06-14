/* global React, Icon */
function WeaponsRack({ active = 1 }) {
  const slots = ["missile", "missile", "missile"];
  return (
    <div>
      <div style={{
        font: '500 11px "JetBrains Mono"', letterSpacing: "0.22em", textTransform: "uppercase",
        color: "rgba(255,245,232,0.65)", textShadow: "0 1px 8px rgba(0,0,0,0.5)",
        marginBottom: 10, textAlign: "right",
      }}>Weapons</div>
      <div style={{ display: "flex", gap: 14, justifyContent: "flex-end" }}>
        {slots.map((s, i) => {
          const isActive = i === active;
          return (
            <Icon key={i} name={s} size={26}
                  color={isActive ? "#ffb347" : "#fff5e8"}
                  style={isActive ? { filter: "drop-shadow(0 1px 6px rgba(255,179,71,0.5))" } : {}}/>
          );
        })}
      </div>
    </div>
  );
}
window.WeaponsRack = WeaponsRack;
