# Horizon — Guía de aplicación para Claude Code (iOS / SwiftUI)

> Lee este documento **antes** de tocar la pantalla de juego. Cubre el diagnóstico de la build actual (la del simulador iPhone 17, captura `15:37`), los assets que tienes en `ios-assets/`, y el **orden exacto** en que aplicarlos.

---

## 1. Diagnóstico — qué está mal en la captura

Comparada con `design-system/screens.md` → "Gameplay" y "iPhone (844×390 landscape)", la pantalla actual tiene **siete** desviaciones del sistema. Listadas por gravedad:

| #  | Problema observado                                                                                                          | Regla violada                       |
|----|-----------------------------------------------------------------------------------------------------------------------------|-------------------------------------|
| 1  | El **botón de cerrar (×)** se solapa horizontalmente con la columna `SCORE / 10`. No tiene espacio propio.                  | `screens.md` → padding 22pt + columna izquierda reservada al ScorePanel |
| 2  | La **retícula** está dibujada como cruz `+` con corchetes pegados al avión. Spec pide dos `[ ]` flanqueando un `+` pequeño, **centrada y a 47% del alto** sobre el sol — no sobre el avión. | `components.md` §3              |
| 3  | El avión + las explosiones están **sobre el HUD**: el sistema dice que el jet es **parte del fondo** (`starfox-bg.png`). No se debe dibujar un sprite de avión encima. | `principles.md` §6 + `screens.md` "No hero craft SVG"           |
| 4  | El **botón de disparo (scope, abajo-derecha)** rompe el grid: invade el espacio del `WeaponsRack` y del padding inferior.   | `screens.md` 4-corner HUD            |
| 5  | El **shield bar** parece tener `border-radius` de píldora. Debe ser `--radius-1` (2pt), bordes casi rectos.                  | `components.md` §4 + `principles.md` §4 |
| 6  | La **barra naranja inferior** (home indicator decorativo) no es del sistema. El home indicator del sistema iOS basta.        | `principles.md` "Don't" — no chrome inventado |
| 7  | El **multiplier `×1.0`** está en color ember (naranja). Ember solo se enciende cuando `multiplier ≥ 2.0`.                    | `principles.md` §3 — accents = state |

Además, la captura muestra que el **fondo** sí está bien aplicado (`starfox-bg.png` full-bleed). Eso lo conservamos.

---

## 2. Qué te entrego (carpeta `ios-assets/`)

```
ios-assets/
├── Assets.xcassets/
│   ├── Contents.json
│   ├── HorizonBackground.imageset/        ← starfox-bg.png como `Image("HorizonBackground")`
│   │   ├── Contents.json
│   │   └── horizon-bg.png
│   └── Colors/                            ← namespace habilitado
│       ├── Sky/        (5 colorsets — deep, plum, ember, flare, haze)
│       ├── Silhouette/ (5 colorsets — far, mid, near, ridge, void)
│       ├── Ink/        (4 colorsets — bone, haze, dim, ghost)
│       ├── Accent/     (5 colorsets — ember, flare, core, shieldCyan, warn)
│       └── Surface/    (4 colorsets — panel, panelHi, hairline, divider)
└── Sources/
    ├── HorizonTokens.swift        ← namespace `Horizon.*` (color, space, radius, motion)
    ├── HorizonTypography.swift    ← `Horizon.Type.*` + tracking helpers
    ├── HorizonHUD.swift           ← ScorePanel, WavePanel, Reticle, ShieldBar, WeaponsRack, HorizonPanel, HorizonBackground
    └── GameplayScreen.swift       ← layout completo de referencia
```

Los 23 colorsets siguen los hex de `design-system/tokens.css` (sRGB, alpha incluido para `dim`/`ghost`/`surface`). Los nombres tienen namespace por carpeta — referencia con `"Sky/SkyEmber"`, no `"SkyEmber"`. Los helpers de `HorizonTokens.swift` ya hacen eso por ti.

---

## 3. Cómo instalarlo en el proyecto Xcode (orden estricto)

1. **Copia** la carpeta `ios-assets/Assets.xcassets/` al target del juego. Si ya hay un `Assets.xcassets`, **fusiónalo**: arrastra los grupos `Colors/` y `HorizonBackground.imageset/` adentro. Verifica en el inspector que cada `colorset` tenga "Provides Namespace" activado en sus carpetas (Sky, Silhouette, Ink, Accent, Surface).
2. **Copia** los cuatro `.swift` de `ios-assets/Sources/` al target. Mantén el namespace `Horizon` — no renombres.
3. **Fuentes.** El sistema usa **dos** familias y solo dos:
   - `Inter Tight` — pesos 200, 300, 400, 500 + itálicas 300/400.
   - `JetBrains Mono` — pesos 300, 400, 500.
   Descárgalas de Google Fonts, añádelas al target (Build Phases → Copy Bundle Resources), y regístralas en `Info.plist` bajo `UIAppFonts` con los nombres de archivo `.ttf`. Verifica el PostScript name con Font Book — debe coincidir con `InterTight-ExtraLight`, `JetBrainsMono-Light`, etc. Si difiere, ajusta el string en `HorizonTypography.swift`.
4. **Compila**. Si Xcode se queja del namespace de los colors (`Sky/SkyEmber`), abre el Asset Catalog → selecciona la carpeta `Sky` → en el inspector marca **Provides Namespace**. Repite para `Silhouette`, `Ink`, `Accent`, `Surface`.

---

## 4. Cómo arreglar la pantalla de juego — orden exacto

Aplica los pasos en este orden. Cada uno es independiente del siguiente, pero hacerlos en otro orden te obligará a re-tocar cosas.

### Paso 1 — Sustituye toda la pantalla por el layout canónico
Reemplaza el cuerpo de tu `GameplayView` (o como se llame) por `GameplayScreen` de `Sources/GameplayScreen.swift`, o cópialo como base. Esto te da los 4 cuadrantes, padding 22pt y la retícula al 47% — gratis y correcto.

### Paso 2 — Reemplaza el avión hecho a mano por el sprite del sistema
El jet de la build actual está dibujado como un sprite genérico encima del HUD y se solapa con todo. El paquete trae el sprite ya listo:

- `Assets.xcassets/JetSprite.imageset/` — incluye `jet@2x.png` (1536×1024) + `jet@3x.png` (2304×1536), fondo transparente.
- `Sources/JetSprite.swift` — componente SwiftUI con llamas procedurales tokenizadas (`Accent.flare/ember/core`) y banking opcional.

Úsalo en `GameplayScreen` debajo del scrim y por encima del fondo. Detalles completos en `ios-assets/JetSprite.README.md`.

```swift
GeometryReader { g in
    JetSprite(flames: true, width: g.size.width * 0.38, bank: 0)
        .position(x: g.size.width * 0.5, y: g.size.height * 0.72)
}
.allowsHitTesting(false)
```

Borra cualquier `Path`, `SpriteView` o `Image("plane")` antiguo que estuviera dibujando el avión por código.

### Paso 3 — Reposiciona el botón de cerrar
- Quítalo del solapamiento con `SCORE`.
- Opción A (recomendada por el sistema): **elimínalo durante el gameplay**. La pausa se invoca con un gesto (tap-hold o un botón pause discreto en la esquina inferior, fuera del flujo visual). Ver `screens.md` → "Pause".
- Opción B (si el producto exige un cerrar visible): muévelo a la esquina inferior-izquierda como un GhostButton circular pequeño (32pt), o ponlo arriba-izquierda **en su propia fila por encima** del ScorePanel, separado por `Horizon.Space.s4`.

### Paso 4 — Arregla la retícula
Sustituye el dibujo actual por el componente `Reticle(size: 56)`. Posiciónala con `GeometryReader` en `(x: width*0.5, y: height*0.47)` — sobre el sol, **no** sobre el avión. Tamaño 56pt en iPhone landscape (compact), 72pt en iPad/desktop.

### Paso 5 — Arregla el shield bar
Sustituye por `ShieldBar(value: 0.55)`. El componente ya aplica `--radius-1`, borde 1.5pt, padding interior 2pt, y cambia a `Accent.warn` cuando `value < 0.30`. **No** uses `Capsule()`.

### Paso 6 — Botón de disparo
Si el juego necesita un FAB de disparo táctil (lo veo en la captura), no es parte del sistema actual. Tienes dos caminos:

- **Quítalo** y dispara con tap en cualquier punto de la pantalla (como un shoot-em-up clásico). Es lo que el sistema parece asumir.
- **Mantenlo** pero sigue las reglas: círculo de 56pt, `Surface.panel` fill, `Ink.bone @ 40%` border, posicionado **debajo** de la columna de `WeaponsRack` con `Horizon.Space.s3` de gap, no a su lado. `GameplayScreen.swift` muestra una versión de referencia — cópiala.

Decide con el dueño del producto y registra la decisión en `components.md` antes de quedarte con una.

### Paso 7 — Multiplier color
Cambia el binding del color a `multiplier >= 2.0 ? Horizon.Accent.ember : Horizon.Ink.bone`. `WavePanel` ya lo hace; si lo tienes inline, copia esa lógica.

### Paso 8 — Borra la barra naranja inferior
La franja decorativa naranja en el borde inferior no existe en el sistema. iOS ya pinta el home indicator. Bórrala.

### Paso 9 — Audita el resto del código contra los tokens
Busca y elimina:
- Cualquier `Color(red:..., green:..., blue:...)` o `Color(hex:...)` → reemplaza por `Horizon.<grupo>.<token>`.
- Cualquier `Color.white` → `Horizon.Ink.bone`.
- Cualquier `Color.black` para fondos → `Horizon.Silhouette.void`.
- Cualquier `Font.system(...)` para HUD numerics → `Horizon.Type.readoutLg / readoutSm / label`.
- Cualquier `Font.system(...)` para narrativa → `Horizon.Type.title / heading / body`.
- Cualquier `cornerRadius:` con números crudos → `Horizon.Radius.*`.
- Cualquier `padding(...)` con números crudos → `Horizon.Space.*`.

Si encuentras un valor que **no** está en el sistema, **no lo añadas inline**. Añádelo a `tokens.css` + `tokens.json` + `HorizonTokens.swift` a la vez, o pregunta.

---

## 5. Reglas duras (recordatorio)

Estas son las mismas seis reglas de `principles.md` aplicadas al contexto Swift:

1. **Solo tokens.** Nunca un hex, fuente, spacing o duración inline. Si falta, se añade al sistema, no al call site.
2. **Dos tipografías.** Inter Tight + JetBrains Mono. SF Pro / Helvetica / system fonts están prohibidos en este target.
3. **Fondo = imagen.** `Image("HorizonBackground")` full-bleed en cada pantalla. No redibujes cielo/montañas/jet en `Canvas`/`Path`.
4. **Acentos = estado.** `Accent.ember` solo cuando hay algo que decir (multiplier ≥2, NEW RECORD, etc.). Si todo brilla, nada brilla.
5. **Sombra de texto en HUD.** Cualquier `Text` sobre el cielo lleva `.horizonHUDTextShadow()`.
6. **HUD afilado.** Score / shield / telemetry / reticle → `Radius.r0` o `r1`. Botones / cards → `r2`. Píldoras → `full`.

---

## 6. Validación rápida (checklist visual)

Cuando creas que terminaste, abre el simulador en iPhone 17 landscape y compara contra `design-system/screens.md` "Gameplay":

- [ ] Sin sprites de avión / explosiones encima del fondo.
- [ ] Retícula `[ + ]` centrada al 47% del alto, sobre el sol.
- [ ] Score arriba-izquierda, Wave arriba-derecha, Shield abajo-izquierda, Weapons abajo-derecha. Padding 22pt.
- [ ] `×1.0` en `Ink.bone`. Solo cambia a `Accent.ember` cuando subes a `×2.0`.
- [ ] Shield bar con esquinas casi rectas (2pt), borde fino, fill bone.
- [ ] Botón cerrar fuera del flujo de Score, o eliminado durante gameplay.
- [ ] Sin franja naranja inferior decorativa.
- [ ] Todo el texto del HUD lleva sombra (`.horizonHUDTextShadow()`).
- [ ] No hay un solo hex literal ni `Color.white` ni `Font.system` en el código del juego.

---

## 7. Si algo no encaja

No hagas un one-off. Antes de inventar un color, una sombra, o un radio nuevo:
1. Busca en `components.md` el componente más cercano y **extiéndelo**.
2. Si el sistema no lo cubre, abre un PR a `tokens.css` + `tokens.json` + `HorizonTokens.swift` proponiendo el token, con justificación.
3. Si la decisión es de producto (ej. botón de disparo táctil), documéntala en `components.md` antes de mergear.

— Fin —
