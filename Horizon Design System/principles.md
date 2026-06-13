# StarFox / Horizon — Visual Principles

Six rules. Apply them before reaching for tokens.

## 1. Atmosphere over chrome
The sky **is** the UI. HUD elements are minimal floating type and outlines — never opaque toolbars or solid panels over the scene. If a panel is unavoidable (menus, results), it's glass: `rgba(10,6,18,0.55)` + `backdrop-filter: blur(14px)`.

## 2. Two voices, no third
- **Inter Tight** = narrative, menus, screen titles, taglines. Light weights (200–300) at large sizes; 400 at body.
- **JetBrains Mono** = HUD numerics, labels, telemetry. Always tracked-out (`0.22em`) for labels, tight (`-0.02em`) for big numerics.

Don't introduce a third typeface. Don't use mono for narrative copy or display for numeric readouts.

## 3. Color is climate, accents are signals
The sunset palette (`--sky-*`, `--silhouette-*`, `--ink-*`) is the world. The accents (`--accent-ember`, `--accent-flare`, `--accent-warn`) only fire when the game has something to say:

- `ember` — multiplier ≥ 2, NEW RECORD, completed-mission stars
- `flare` — active lock-on, engine glow
- `warn` — shield critical, error
- `shield-cyan` — momentary (shield charge pickup)

If everything is highlighted, nothing is.

## 4. Sharp readouts, soft narrative
Radius scale by intent:
- HUD readouts, shield bar, telemetry strip → `--radius-0`/`--radius-1` (sharp, instrumented)
- Buttons, mission cards, panels → `--radius-2` (4px)
- Pills, badges, multiplier chip → `--radius-full`

## 5. Always shadow HUD type
Anywhere text sits over the sky, apply `text-shadow: var(--shadow-text-hud)`. The sky is bright at the horizon and pure black ink would still wash; off-white type with a soft drop reads on every gradient stop.

## 6. The reference image is canonical
Use `assets/starfox-bg.png` as the background for every gameplay/menu screen via `background-image: url('...'); background-size: cover; background-position: center;`. Do not redraw the scene in SVG. Do not try to procedurally generate a similar one. If you need different moods, ask for a new render — don't fork the system.

---

## Don't

- ❌ Pure white (`#fff`) — use `--ink-bone` (`#fff5e8`).
- ❌ Pure black backgrounds for screens — use `--silhouette-void` (`#0a0612`).
- ❌ Drop-shadows on cards/panels (the glass effect carries depth).
- ❌ Gradients on buttons (they're solid or transparent).
- ❌ Emoji in UI copy.
- ❌ Rounded corners on the HUD readouts.
- ❌ Animated backgrounds (the sky is a still image; only HUD elements animate).
