---
name: horizon-design
description: Use this skill to generate well-branded interfaces and assets for Horizon, an arcade flight game with an atmospheric sunset aesthetic — either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

# Horizon — design skill

Read `README.md` within this skill folder, then explore the other available files. Foundations live in `tokens.css`, `colors_and_type.css`, `principles.md`, `components.md`, `screens.md`. Brand assets live in `assets/`. A full click-thru UI kit lives in `ui_kits/horizon/` (load `index.html` in a browser to see it).

## Working rules

- **The aesthetic is one unbroken sunset.** Single hero image (`assets/starfox-bg.png`), warm-to-cool gradient, silhouetted foreground, instruments floating over. Don't redraw the sky in SVG.
- **Two typefaces only.** Inter Tight for display + body (200/300 for display; 400/500 for UI text). JetBrains Mono for telemetry, labels, tickers — `letter-spacing: 0.22em–0.32em`, `text-transform: uppercase`.
- **Tokens, not raw values.** Every color, font-size, radius, and shadow is in `tokens.css`. If you find yourself writing a hex code, you're off-system.
- **Subtle motion only.** 160–240ms cubic-bezier(0.2, 0.7, 0.2, 1). No bounces. Hover = lighten by 4%; press = scale(0.98).
- **The HUD is baked into the background image.** On non-gameplay screens, mask the four corners with `<HudMask>` (in `ui_kits/horizon/HudMask.jsx`) or equivalent dark radial pads.

## When to use

If creating visual artifacts (slides, mocks, throwaway prototypes, marketing one-pagers, etc.), copy assets out of this skill and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with the Horizon brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.
