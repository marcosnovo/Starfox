# StarFox / Horizon — Screen Specifications

All screens are 16:9 landscape. iPhone landscape uses an 844×390 viewport. The reference image (`assets/starfox-bg.png`) is the background for every screen.

---

## Cover (1280×720)

```
┌─────────────────────────────────────────────────┐
│ AN ARCADE FLIGHT GAME · 2026                    │ ← eyebrow, mono, --ink-haze
│                                                 │
│ Horizon                                         │ ← display 128 / 200 / -4%
│ Chase the light.                                │ ← italic 22, --ink-haze
│                                                 │
│                                                 │
│                                                 │
│                                                 │
│                                                 │
│                          DESIGN SYSTEM          │
│                          v1.0 · APR 2026        │ ← mono, --ink-dim
└─────────────────────────────────────────────────┘
```
- Background: reference image, full-bleed.
- Scrim: `--gradient-scrim-top` + `--gradient-scrim-bottom` for legibility.
- Title block: top-left, padding 56px.
- Stamp: bottom-right, padding 56px.

---

## Gameplay (960×540, scales to device)

The HUD lives at the four corners. Padding 24px from each edge.

```
┌─────────────────────────────────────────────────┐
│ SCORE              [reticle]            WAVE    │
│ 2,450                                   03      │
│ RINGS                                MULTIPLIER │
│ 23                                      ×2.0    │ ← --accent-ember when ≥ 2
│                                                 │
│                  [+]                            │ ← reticle, 72px
│                                                 │
│                                                 │
│                                                 │
│ SHIELD                              WEAPONS     │
│ ▓▓▓▓░░░░░░                          ◆ ◆ ◆       │
└─────────────────────────────────────────────────┘
```

- Reticle is at 47% from top (sits over the sun in the reference image).
- No hero craft SVG — the jet is part of the background.
- All HUD type uses `text-shadow: var(--shadow-text-hud)`.

---

## Title (960×540)

```
┌─────────────────────────────────────────────────┐
│           AN ARCADE FLIGHT GAME                 │
│                                                 │
│              [HORIZON brand mark]               │ ← BrandMark size=0.85
│              Chase the light.                   │
│                                                 │
│                                                 │
│                  [ Begin ]                      │ ← PrimaryButton
│              [Records] [Settings]               │ ← GhostButton x2
└─────────────────────────────────────────────────┘
```
- Background: reference image.
- Scrim: vignette only (top + bottom).
- Vertical layout: eyebrow (top), mark (center), CTAs (bottom).

---

## Pause (960×540)

A paused gameplay frame with an extra full-bleed scrim.

```
┌─────────────────────────────────────────────────┐
│ SCORE 2,450                       WAVE 03       │ ← compact HUD still visible
│ RINGS 23                          ×2.0          │
│                                                 │
│                                                 │
│                  PAUSED                         │ ← eyebrow
│            Catch your breath.                   │ ← display 56 / 200 / -3%
│                                                 │
│             [ Resume ]  [Quit run]              │
│                                                 │
│           ALT 12,840 · SPD 0.82 · HDG 287       │ ← TelemetryStrip
└─────────────────────────────────────────────────┘
```
- Scrim: `rgba(10,6,18,0.55)` + `backdrop-filter: blur(6px)` over entire screen.

---

## Mission Select (960×540)

```
┌─────────────────────────────────────────────────┐
│ SELECT WAVE                              [Back] │
│ Long flight                                     │ ← title 40
│                                                 │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐                │
│ │WV01 │ │WV02 │ │WV03 │ │WV04 │                │ ← MissionCard x4
│ │First│ │ The │ │Cald-│ │Long │                │
│ │Light│ │Pass │ │ era │ │Night│                │
│ │ ●●● │ │ ●●○ │ │  →  │ │  🔒 │                │
│ └─────┘ └─────┘ └─────┘ └─────┘                │
│                                                 │
│ BEST     RINGS    RUNS              [ Launch ] │ ← stats strip
│ 14,820   1,248    47                            │
└─────────────────────────────────────────────────┘
```
- Scrim: uniform `rgba(10,6,18,0.55)` + `blur(2px)`.
- Stats strip: glass panel, padding 16, gap 24.

---

## Results (960×540)

```
┌─────────────────────────────────────────────────┐
│ RUN COMPLETE — WAVE 03                          │
│ Caldera, cleared.                               │ ← display 56 / 200
│                                                 │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐            │
│ │SCORE │ │RINGS │ │ BEST │ │DURATN│            │ ← stat cards (glass)
│ │12,450│ │  84  │ │ ×4.0 │ │ 3:42 │            │
│ └──────┘ └──────┘ └──────┘ └──────┘            │
│                                                 │
│ 🏆  NEW RECORD                       +2,400    │ ← achievement card, ember border
│     Longest chain on Caldera                    │
│                                                 │
│ [ Fly again ]  [Mission select]  [Leaderboard] │
└─────────────────────────────────────────────────┘
```
- Achievement card: `border: 1px solid rgba(255,179,71,0.4)`, otherwise glass panel.
- Stat cards: 4-col grid, gap 14.

---

## iPhone (844×390 landscape)

Identical to Gameplay but with `compact` HUD variants (~25% smaller readouts), padding 22px, reticle 56px.

Use `IOSFrame` (provided in prototype) or any device bezel. Inside the safe-area bezel, the HUD must clear the notch on the left edge — keep score panel inset 22px from the visible viewport, not from the device chrome.
