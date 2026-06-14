# StarFox / Horizon — Component Specifications

Each component below has: purpose, anatomy, props, states, and a reference HTML snippet using token CSS variables. Pair with `tokens.css`.

---

## 1. ScorePanel  (top-left HUD)

**Purpose** — primary readouts during gameplay (score + rings).
**Anatomy** — vertical stack, two label/value pairs.

| Element       | Token                                                     |
|---------------|-----------------------------------------------------------|
| Label         | `--font-mono` 10–11px / 500 / `--tracking-label` / `--ink-dim` |
| Value (score) | `--font-mono` 38px / 300 / `--tracking-readout` / `--ink-bone` |
| Value (rings) | `--font-mono` 28px / 300 |
| Gap           | `--space-4` between pairs |
| Text shadow   | `--shadow-text-hud` (always on, for legibility over sky)  |

**Props** — `score: number`, `rings: number`, `compact?: boolean` (drops sizes by ~25%).

```html
<div class="score-panel">
  <div class="readout">
    <div class="label">SCORE</div>
    <div class="value-xl">2,450</div>
  </div>
  <div class="readout">
    <div class="label">RINGS</div>
    <div class="value">23</div>
  </div>
</div>
```

---

## 2. WavePanel  (top-right HUD)

Mirror of ScorePanel, right-aligned. Multiplier turns `--accent-ember` when `≥ 2.0`.

**Props** — `wave: number` (zero-padded to 2 digits), `multiplier: number` (one decimal, prefixed `×`), `compact?: boolean`.

---

## 3. Reticle  (center HUD)

**Anatomy** — Two square brackets `[ ]` flanking a small `+` crosshair. No dotted ring, no corner ticks.

```
   ┌         ┐
   │    +    │
   └         ┘
```

**Props** — `size?: number` (default 72), `locked?: boolean` (switches stroke from `--ink-bone` to `--accent-flare`).
**Stroke** — `--stroke-thin` (1.5px), `strokeLinecap: "square"`. Drop-shadow `--shadow-icon`.

---

## 4. ShieldBar  (bottom-left HUD)

**Anatomy** — Mono label above; horizontal capsule with 1.5px outline, 2px inner padding, fill bar.

| State        | Fill color           | Trigger             |
|--------------|----------------------|---------------------|
| Healthy      | `--ink-bone`         | `value ≥ 0.30`      |
| Critical     | `--accent-warn`      | `value < 0.30`      |
| Charged (FX) | `--accent-shield-cyan` | momentary, on pickup |

Width 200px, height 12px, radius `--radius-1`. Animate width with `width var(--duration-base) var(--ease-out)`.

---

## 5. WeaponsRack  (bottom-right HUD)

**Anatomy** — Mono label, then a horizontal row of weapon glyphs (`gap: 14px`). Each glyph is 24px, `--ink-bone` stroke.

**States** — `default`: bone stroke. `active`: `--accent-ember` stroke + fill. `disabled`: `--ink-ghost` stroke.

---

## 6. TelemetryStrip  (bottom-center, optional)

A glass strip showing `ALT 12,840ft · SPD 0.82M · HDG 287°`.

```css
.telemetry-strip {
  font-family: var(--font-mono);
  font-size: var(--type-telemetry);
  letter-spacing: 0.18em;
  color: var(--ink-haze);
  display: flex;
  gap: var(--space-6);
  padding: var(--space-2) 18px;
  background: rgba(10,6,18,0.45);
  border: 1px solid var(--surface-hairline);
  border-radius: var(--radius-1);
}
.telemetry-strip .k { color: var(--ink-dim); }
```

---

## 7. Buttons

### PrimaryButton
- Solid `--ink-bone` background, `--silhouette-void` text.
- `--font-mono` 12px / 500 / `--tracking-label` / `text-transform: uppercase`.
- Padding `16px 32px`. Radius `--radius-1`. No shadow.
- Active: `transform: translateY(1px)`.

### GhostButton
- Transparent bg, `1px solid rgba(255,245,232,0.4)` border.
- Same type as PrimaryButton but `--ink-bone` color.
- Optional leading icon (16px), `gap: 10px`.

---

## 8. Panel  (glass card)

```css
.panel {
  background: var(--surface-panel);
  backdrop-filter: var(--blur-glass);
  border: 1px solid var(--surface-hairline);
  border-radius: var(--radius-2);
  padding: var(--space-6);
  color: var(--ink-bone);
}
.panel .kicker {
  font: 500 10px var(--font-mono);
  letter-spacing: var(--tracking-label);
  color: var(--ink-dim);
  margin-bottom: var(--space-2);
}
.panel .title {
  font: 300 22px/1.2 var(--font-display);
  letter-spacing: -0.01em;
  margin-bottom: var(--space-3);
}
```

---

## 9. MissionCard

Fixed-size card (`min-width: 200px; height: 180px`). Glass panel with three statuses:

| Status     | Border                              | Indicator                           | Opacity |
|------------|-------------------------------------|-------------------------------------|---------|
| available  | `--surface-hairline`                | `chevron-r` glyph                   | 1       |
| completed  | `rgba(255,179,71,0.5)`              | 3 dots (filled = stars earned)      | 1       |
| locked     | `--surface-hairline`                | `lock` glyph                        | 0.45    |

Header: `WAVE 0N` (eyebrow) + name (display 22 / 300) + subtitle (caption / dim).

---

## 10. Icon set

24px grid, 1.5 stroke, round caps & joins, outline-only by default. Available glyphs:

`missile · bomb · laser · shield · ring · wave · multiplier · speed · alt · hdg · pause · play · settings · back · lock · trophy · chevron-r`

Active state: switch `stroke` and `fill` to `--accent-ember`. Disabled: `stroke: var(--ink-ghost)`.

---

## 11. Background scene

All gameplay/menu screens use the **reference artwork** (`assets/starfox-bg.png`) as a full-bleed `background-image` with `background-size: cover; background-position: center;`.

For menu screens that need contrast, layer a scrim above:

```css
.scrim-uniform { background: rgba(10,6,18,0.55); backdrop-filter: blur(2px); }
.scrim-pause   { background: rgba(10,6,18,0.55); backdrop-filter: blur(6px); }
.scrim-vignette { background: linear-gradient(180deg,
   rgba(10,6,18,0.45) 0%, rgba(10,6,18,0) 35%,
   rgba(10,6,18,0) 60%, rgba(10,6,18,0.55) 100%); }
```

---

## 12. Brand mark

- **Wordmark**: `HORIZON` in Inter Tight 200, letter-spacing 14, with a horizon line + sun-arc above.
- **Lockup**: compact horizontal version (icon + word).
- **App icon**: 56×56, radius 14, gradient `--sky-deep → --sky-ember → --sky-flare`, with mountain silhouette at bottom and white sun disc.
- **Tagline**: *"Chase the light."* — Inter Tight italic, `--ink-haze`.
