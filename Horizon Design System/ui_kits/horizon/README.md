# Horizon — UI Kit

Interactive recreation of the Horizon arcade-flight-game UI. Single product, one continuous click-thru: **Cover → Title → Mission Select → Gameplay → Pause → Results**.

Built on `tokens.css` + `colors_and_type.css` from the project root. All visuals match the spec in `screens.md` and `components.md`. The canonical sunset image (`assets/starfox-bg.png`) is the background of every screen — never redrawn.

## Files

| File | Role |
|---|---|
| `index.html` | Click-thru demo. Loads React + Babel and mounts `<App />`. |
| `BrandMark.jsx` | Wordmark (HORIZON) + horizon line + sun arc. |
| `HUD.jsx` | Four-corner HUD shell + Score/Wave readouts. |
| `Reticle.jsx` | Center crosshair. `locked` toggles flare color. |
| `ShieldBar.jsx` | Outlined capsule with healthy/critical/charged states. |
| `WeaponsRack.jsx` | Bottom-right weapon glyph row. |
| `TelemetryStrip.jsx` | ALT · SPD · HDG glass strip. |
| `Buttons.jsx` | `PrimaryButton` + `GhostButton`. |
| `Panel.jsx` | Glass card. |
| `MissionCard.jsx` | Available / completed / locked. |
| `Icons.jsx` | Inline SVG icon set. |
| `screens/CoverScreen.jsx` | Brand cover. |
| `screens/TitleScreen.jsx` | Begin / Records / Settings. |
| `screens/GameplayScreen.jsx` | Live HUD. |
| `screens/PauseScreen.jsx` | Pause overlay. |
| `screens/MissionSelectScreen.jsx` | Wave grid. |
| `screens/ResultsScreen.jsx` | Run summary + new record. |

Open `index.html` to step through the prototype.
