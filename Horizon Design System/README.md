# Horizon — Design System

Atmospheric. Cinematic. Instrumented.

Horizon is the design system for **an arcade flight game** of the same name. The visual world is a single, unbroken sunset — a lone jet chasing the last light over silhouetted mountains. The UI doesn't decorate that scene; it floats over it like cockpit telemetry.

---

## Sources

This system was assembled from a handoff folder (`design-system/`) provided by the product team. Original sources:

- **Codebase / handoff:** `design-system/` — design tokens, principles, component specs, screen layouts, and a reference background image. Mirrored into this project root.
  - `tokens.css` — CSS custom properties (single source of truth).
  - `tokens.json` — same tokens, machine-readable (Style Dictionary friendly).
  - `principles.md` — six visual rules; read before designing anything new.
  - `components.md` — component anatomy, props, states.
  - `screens.md` — layout specs for every screen in the prototype.
  - `assets/starfox-bg.png` — canonical reference background. Use as `background-image` on every gameplay/menu screen; **never** redraw in SVG.
- **Figma:** none provided.
- **Live URL:** none provided.

The handoff is internally consistent and high-fidelity, so this design system is built directly on top of it (re-exporting tokens, layering semantic aliases, and recreating the screens as a modular UI kit). No screenshots were used as a primary source.

---

## Product context

**Horizon** is a single-product, single-surface system: a 16:9 arcade flight game playable on desktop and iPhone (landscape, 844×390). There is no marketing site, docs site, or auth product. There are six core screens:

| Screen | Purpose |
|---|---|
| Cover | Brand wordmark + tagline. The "title card." |
| Gameplay | Live HUD floating over the sunset. Score, wave, multiplier, reticle, shield, weapons. |
| Title | Begin / Records / Settings entry menu. |
| Pause | Compact HUD + scrim + Resume / Quit. |
| Mission Select | Wave picker grid with mission cards (available / completed / locked). |
| Results | Run summary — stat cards + new-record callout. |

Tagline: *"Chase the light."*

---

## Brand voice

**Atmospheric, cinematic, instrumented.** The product reads like an aviation HUD merged with a sunset poster. Two type voices, no third — Inter Tight for narrative and menus, JetBrains Mono for every numeric readout.

Motion is calm and deliberate: 160–480ms with a soft `cubic-bezier(0.2, 0.7, 0.2, 1)` ease-out. Color is climate, not decoration. Accents only fire on meaningful state (multiplier ≥ 2, lock-on, low shield).

---

## Content Fundamentals

Copy in Horizon is **terse, evocative, and aviation-flavored**. It's the voice of a flight instructor who's also a poet — short, declarative, occasionally lyrical. Never chatty, never marketing-bro, never gamified hype.

### Tone & vibe
- **Atmospheric over expository.** "Caldera, cleared." not "You completed the Caldera mission!".
- **Cinematic punctuation.** Sentence fragments are fine. Periods carry weight. Em-dashes for pacing.
- **Instrumented.** Numbers are first-class — "ALT 12,840 ft · SPD 0.82 M · HDG 287°".
- **No exclamation marks.** Ever. The game doesn't shout.
- **No emoji.** Anywhere in the UI. (Use the icon set or unicode glyphs like `→ · ◆`.)

### Voice rules
- **Second person, sparingly.** "Catch your breath." reads as a director's note, not a chatbot. Avoid "you" in stat labels and HUD.
- **No "I" voice.** The system never speaks as itself.
- **Imperative for CTAs.** *Begin · Resume · Launch · Fly again · Quit run* — verbs first, never "Click to begin."
- **No questions in copy.** "Ready to fly?" → never. State the situation; let the player respond.

### Casing
- **HUD labels:** `UPPERCASE` — `SCORE`, `RINGS`, `WAVE`, `MULTIPLIER`, `SHIELD`, `WEAPONS`, `ALT`, `SPD`, `HDG`. Tracked +22% (`0.22em`).
- **Eyebrows:** `UPPERCASE` tracked +32% (`0.32em`) — `AN ARCADE FLIGHT GAME · 2026`.
- **Buttons:** `UPPERCASE` mono — `LAUNCH`, `RESUME`, `BACK`. Tracked +22%.
- **Display titles:** `Sentence case` — *Horizon · Caldera, cleared · Catch your breath.*
- **Mission names:** `Sentence case` — *First Light · The Pass · Caldera · Long Night*.

### Copy specimens
| Where | Copy |
|---|---|
| Tagline | *Chase the light.* |
| Cover eyebrow | `AN ARCADE FLIGHT GAME · 2026` |
| Pause | *Catch your breath.* |
| Results title | *Caldera, cleared.* |
| Achievement | `NEW RECORD` — *Longest chain on Caldera* |
| Title CTA | `BEGIN` / `RECORDS` / `SETTINGS` |
| HUD telemetry | `ALT 12,840 ft · SPD 0.82 M · HDG 287°` |
| Mission subtitle | *The pass narrows. Hold steady.* |

If a string needs more than ten words, write less. If it needs fewer than three, you're probably right.

---

## Visual Foundations

### Background
The **canonical reference image** (`assets/starfox-bg.png`) is the background of every gameplay/menu screen. It's a still, painterly sunset — deep plum at the top, ember in the middle band, pale haze at the horizon, with five layers of mountain silhouette receding into atmospheric haze and a hero jet trailing twin engine flares. It is **never** procedurally redrawn, animated, or filtered. Apply it via `background-image: url(...); background-size: cover; background-position: center;` and layer scrims on top.

Backgrounds are **never** plain colors except in print/export contexts; if you need a solid backdrop for a doc, use `--silhouette-void` (`#0a0612`).

### Color system
Five families, each with a clear job:

- **Sky** (`--sky-deep · plum · ember · flare · haze`) — the gradient stops of the sunset. Used in the canonical image and the `--gradient-sky-dusk` token; rarely as flat fills.
- **Silhouette** (`--silhouette-far · mid · near · ridge · void`) — mountain layers, back to front. `--silhouette-void` (`#0a0612`) is the page background.
- **Ink** (`--ink-bone · haze · dim · ghost`) — type and UI strokes. `bone` is off-white (`#fff5e8`), never pure white. `dim` and `ghost` are bone with reduced alpha.
- **Accent / signal** (`--accent-ember · flare · core · shield-cyan · warn`) — fires only on meaningful state. If everything is highlighted, nothing is.

Color is climate. The sunset palette **is** the world; accents are the system saying something.

### Type
**Inter Tight** (200 / 300 / 400 / 500 + italic 300 / 400) for everything narrative — display, titles, body, italic taglines. Light weights (200–300) at large sizes; 400 at body. Tight tracking on display (`-0.04em`), looser on body.

**JetBrains Mono** (300 / 400 / 500) for every numeric readout — score, wave, multiplier, telemetry, labels. Tracked-out for labels (`0.22em`), tight for big numerics (`-0.02em`). Always uppercase for labels.

No third typeface. No mono for narrative. No display for numbers.

### Spacing & geometry
- **4pt base scale:** 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64. Standard screen padding is 24px from each edge; iPhone is 22px.
- **Radius scale by intent:** 0–2px for HUD readouts (sharp, instrumented); 4px for buttons / cards / panels; full for pills and the multiplier chip.
- **Stroke weights:** hairline 1px / thin 1.5px / medium 2px / bold 3px. Icons and reticles default to 1.5px with `square` linecaps.
- **Layout grid:** four-corner HUD on every gameplay-class screen (top-left score, top-right wave, bottom-left shield, bottom-right weapons). Reticle at center, ~47% from top to sit over the sun.

### Surfaces & blur
There are **no opaque toolbars or solid panels** over the sky. When a panel is unavoidable (Results, Pause, Mission Select), it's **glass**: `rgba(10, 6, 18, 0.55)` + `backdrop-filter: blur(14px)` + a 1px hairline border. Pause uses a stronger global `blur(6px)` scrim over the entire screen.

Three reusable scrims:
- `scrim-uniform` — `rgba(10,6,18,0.55)` + `blur(2px)` (Mission Select).
- `scrim-pause` — `rgba(10,6,18,0.55)` + `blur(6px)` (Pause).
- `scrim-vignette` — top + bottom gradient only (Title, Cover).

### Borders, shadows, transparency
- **Hairline borders** (`rgba(255,245,232,0.12)`) on glass panels and dividers.
- **No drop-shadows on cards or panels** — the glass effect carries depth.
- **Always shadow HUD type** with `text-shadow: 0 1px 8px rgba(0,0,0,0.5)` (`--shadow-text-hud`). The bright horizon would otherwise wash out off-white type.
- Icons get `drop-shadow(0 1px 6px rgba(0,0,0,0.55))` (`--shadow-icon`) for the same reason.
- Transparency is everywhere — surfaces, dividers, dim/ghost ink. Avoid solid fills above the sky.

### Buttons & interactive states
- **Primary button:** solid `--ink-bone` background, `--silhouette-void` text, mono uppercase, 4px radius, `16px 32px` padding. **Active** = `transform: translateY(1px)`. No gradient. No shadow.
- **Ghost button:** transparent, 1px hairline border (`rgba(255,245,232,0.4)`), bone text, same type as primary.
- **Hover** = subtle border / text brightening (bone at full opacity). No color shifts on hover; the system stays calm.
- **Press** = 1px Y translate. No scale-down. No color flash.
- **Disabled** = `--ink-ghost` (0.35α) on text and stroke; the element loses presence rather than gaining a different state.

### Iconography defaults
24px grid, 1.5px stroke, round caps + joins, outline-only, `--ink-bone` stroke. Active state switches stroke and fill to `--accent-ember`. Disabled icons drop to `--ink-ghost`. (See **ICONOGRAPHY** below.)

### Motion
Calm and deliberate. Three durations: `fast` (160ms), `base` (220ms), `slow` (480ms). One ease: `--ease-out` = `cubic-bezier(0.2, 0.7, 0.2, 1)`. No bounces, no springs, no parallax, no animated gradients. Backgrounds are still images — only HUD elements animate (shield bar fill, multiplier pulse on change, reticle lock-on stroke swap).

### Imagery vibe
**Warm, painterly, dusk-toned.** The reference image is golden-orange in the middle band, deep plum at top, with cool steel-purple silhouettes. There's natural film grain in the sky gradient (subtle banding artifacts, not a noise overlay). No b&w. No cool-only palettes. No photorealistic textures.

### Layout rules (fixed elements)
- **HUD corners** are fixed in viewport space, never scroll.
- **Reticle** is fixed center, slightly above true center.
- **CTAs** in menus are bottom-aligned with 32–48px from the bottom edge.
- **Telemetry strip** (when shown) is bottom-center, glass panel, padding `8px 18px`.

---

## Iconography

Horizon uses a **single hand-built outline icon set** — 24px grid, 1.5px stroke, round caps and joins, outline-only by default. The system does **not** use an icon font, sprite sheet, or third-party icon library.

### Available glyphs (per `components.md`)

`missile · bomb · laser · shield · ring · wave · multiplier · speed · alt · hdg · pause · play · settings · back · lock · trophy · chevron-r`

These are drawn inline as SVG using token CSS variables for stroke / fill color. They are exported in `assets/icons/` for direct reuse — copy these into your project rather than re-drawing.

### Style rules
- **Stroke:** `var(--stroke-thin)` = 1.5px.
- **Caps + joins:** `round`.
- **Default color:** `--ink-bone`.
- **Active state:** stroke and fill swap to `--accent-ember`.
- **Disabled state:** stroke drops to `--ink-ghost` (`rgba(255,245,232,0.35)`).
- **Icons over the sky** always get `filter: drop-shadow(0 1px 6px rgba(0,0,0,0.55))` (`--shadow-icon`).
- **Grid:** all icons are designed to a 24×24 viewBox, with 2px optical padding inside the box.

### Substitution flag

> ⚠️ The handoff inventoried glyphs but did **not** ship SVG source files for the full set. The icons in `assets/icons/` are **substituted** — drawn from scratch to match the spec (1.5px outline, 24px grid, round caps). If you have the canonical icon source, drop them into `assets/icons/` and they'll override these. Closest CDN equivalent for missing glyphs: **[Lucide](https://lucide.dev)** (same stroke weight + cap style); use only as a temporary fallback and flag the substitution to the team.

### What's NOT used
- ❌ Emoji in UI copy. Anywhere.
- ❌ Filled icons (except the active-state fill on weapon glyphs).
- ❌ Color-loaded icons (gradient or multi-color).
- ❌ Different stroke weights inside a single screen.
- ✅ Unicode separators are fine: `·`, `→`, `◆`, `●`, `○`. The mission-card status indicator uses three filled/outline circles to show stars earned.

---

## Index — what's in this folder

```
/
├── README.md                  ← this file
├── SKILL.md                   ← skill manifest (works as Claude Code Agent Skill too)
├── tokens.css                 ← CSS custom properties — single source of truth
├── tokens.json                ← same tokens, machine-readable
├── colors_and_type.css        ← semantic CSS aliases (--fg1, --bg1, --text-h1, …)
├── principles.md              ← six visual rules; read first
├── components.md              ← component anatomy, props, states
├── screens.md                 ← layout specs for every screen
├── assets/
│   ├── starfox-bg.png         ← canonical reference background
│   ├── icons/                 ← outline SVG icon set (substituted — see ICONOGRAPHY)
│   └── logos/                 ← Horizon wordmark + app icon
├── preview/                   ← Design System tab cards (one HTML file each)
│   ├── color-sky.html
│   ├── color-silhouette.html
│   ├── color-ink.html
│   ├── color-accent.html
│   ├── type-display.html
│   ├── type-mono.html
│   ├── …
└── ui_kits/
    └── horizon/               ← the only product surface
        ├── README.md
        ├── index.html         ← interactive click-thru demo (Cover → Title → Gameplay → Results)
        ├── BrandMark.jsx
        ├── HUD.jsx
        ├── Reticle.jsx
        ├── ShieldBar.jsx
        ├── Buttons.jsx
        ├── Panel.jsx
        ├── MissionCard.jsx
        ├── TelemetryStrip.jsx
        ├── Icons.jsx
        └── screens/
            ├── CoverScreen.jsx
            ├── TitleScreen.jsx
            ├── GameplayScreen.jsx
            ├── PauseScreen.jsx
            ├── MissionSelectScreen.jsx
            └── ResultsScreen.jsx
```

No slide deck templates were provided — the `slides/` folder is intentionally absent.

---

## Quick start

```html
<link rel="stylesheet" href="tokens.css">
<link rel="stylesheet" href="colors_and_type.css">
<link href="https://fonts.googleapis.com/css2?family=Inter+Tight:ital,wght@0,200;0,300;0,400;0,500;1,300;1,400&family=JetBrains+Mono:wght@300;400;500&display=swap" rel="stylesheet">
```

Then read `principles.md`. Then build with tokens, never raw values.

---

## File index

Manifest of this design system. All paths relative to the project root.

**Foundations**
- `tokens.css` — CSS custom properties (color, type, spacing, radius, shadow, motion). Single source of truth.
- `tokens.json` — same tokens, machine-readable.
- `colors_and_type.css` — semantic CSS aliases on top of tokens (`--fg-primary`, `--display-xl`, `--meta-mono`, etc.) plus base element styles (`h1`–`h6`, `code`, `kbd`).
- `principles.md` — the six visual rules. Read before designing anything new.
- `components.md` — component anatomy, states, props.
- `screens.md` — layout specs for every screen.

**Brand & assets**
- `assets/starfox-bg.png` — canonical reference background (the sunset). Use as `background-image`; never redraw.
- `assets/wordmark.svg` — "HORIZON" wordmark with reticle bisect.
- `assets/icon-app.svg` — square app icon.
- `assets/reticle.svg` — standalone reticle mark.

**UI kit**
- `ui_kits/horizon/index.html` — interactive click-thru: Cover → Title → Missions → Gameplay → Pause → Results.
- `ui_kits/horizon/README.md` — kit-level notes.
- `ui_kits/horizon/*.jsx` — atomic components (`BrandMark`, `Buttons`, `Icons`, `Panel`, `Reticle`, `ShieldBar`, `WeaponsRack`, `TelemetryStrip`, `MissionCard`, `HudMask`).
- `ui_kits/horizon/screens/*.jsx` — full-screen compositions.

**Preview cards** (rendered in the Design System tab)
- `preview/*.html` — small specimen cards for tokens, type, color, components, brand. ~20 cards across 5 groups.

**Skill metadata**
- `SKILL.md` — Agent Skills manifest; lets you load this design system as a Claude skill outside the project.

---

## Notes & caveats

- **Fonts substituted.** The handoff did not include font files. Inter Tight (Google Fonts) substitutes for the intended display/body family; JetBrains Mono (Google Fonts) substitutes for the mono telemetry face. Both load via Google Fonts at the top of every kit and preview file. Ask the user for the original `.woff2` files if you have them.
- **Iconography is hand-rolled.** No icon library was provided. The 17 outline icons in `ui_kits/horizon/Icons.jsx` follow a 24px grid, 1.5px stroke, round caps, with an ember-active treatment. For new icons, match those rules. If you need a wider library, Lucide is the closest CDN substitute (`https://unpkg.com/lucide@latest`).
- **Single product, single surface.** No marketing site, no docs, no auth. Don't infer or invent screens that aren't in `screens.md`.
- **The HUD is baked into `starfox-bg.png`.** When using the bg on non-gameplay screens, use `<HudMask>` (or your own corner pads) to suppress the four corner labels.
