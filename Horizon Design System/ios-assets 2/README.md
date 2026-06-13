# ios-assets/

Paquete de assets nativos iOS generado a partir del design system Horizon.

**Empieza por `ClaudeCode.md`** — diagnostica la build actual y da el orden exacto de cambios.

```
ios-assets/
├── ClaudeCode.md                  ← LEE ESTO PRIMERO
├── Assets.xcassets/               ← arrastra al target Xcode
│   ├── HorizonBackground.imageset
│   └── Colors/  (Sky, Silhouette, Ink, Accent, Surface — 23 colorsets)
└── Sources/                       ← añade al target
    ├── HorizonTokens.swift        (Color · Space · Radius · Motion · Gradients)
    ├── HorizonTypography.swift    (Inter Tight + JetBrains Mono)
    ├── HorizonHUD.swift           (ScorePanel, WavePanel, Reticle, ShieldBar, WeaponsRack, HorizonPanel, HorizonBackground)
    └── GameplayScreen.swift       (layout canónico de la pantalla de juego)
```

## Fuentes (no incluidas — añade tú al target)

- Inter Tight: pesos 200, 300, 400, 500 + itálicas 300/400
- JetBrains Mono: pesos 300, 400, 500

Regístralas en `Info.plist` bajo `UIAppFonts`. Si los PostScript names difieren de los strings en `HorizonTypography.swift`, ajusta ahí.
