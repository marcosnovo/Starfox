# Jet sprite — listo para usar

El sprite del avión ya está incluido en este paquete:

```
Assets.xcassets/JetSprite.imageset/
├── Contents.json
├── jet@2x.png    ← 1536×1024, fondo transparente
└── jet@3x.png    ← 2304×1536, fondo transparente
```

`Contents.json` está configurado con `template-rendering-intent: original` — los píxeles se conservan tal cual. Si en algún momento quieres tintar el jet desde código (p. ej. flash rojo cuando recibe daño), cambia a `template` y usa `.foregroundColor(Horizon.Accent.warn)`.

---

## Cómo usarlo en la pantalla

En `GameplayScreen.swift`, dentro del `ZStack`, debajo del fondo y por encima del scrim:

```swift
HorizonBackground()
Horizon.Gradients.scrimTop
Horizon.Gradients.scrimBottom

// Hero jet — centrado horizontalmente, abajo del centro vertical.
GeometryReader { g in
    JetSprite(flames: true, width: g.size.width * 0.38, bank: 0)
        .position(x: g.size.width * 0.5, y: g.size.height * 0.72)
}
.allowsHitTesting(false)

// HUD encima …
```

Las llamas las pinta `JetSprite` proceduralmente con los tokens `Accent.flare` + `Accent.ember` + `Accent.core` — no están en la imagen. Si prefieres el avión sin llamas (modo glide), pasa `flames: false`.

### Banking
El parámetro `bank` (-1...1) rota el sprite hasta ±6° para acompañar el input del jugador:

```swift
JetSprite(flames: true, width: 320, bank: tilt)   // tilt animado por el motor de juego
```

---

## Si quieres variantes adicionales

Si más adelante el juego necesita poses específicas (giro brusco izda/dcha, jet dañado con humo), pide a ChatGPT/DALL·E variantes con el mismo estilo y créalas como imagesets independientes:

- `JetSprite-Left.imageset` — `"banking 15° to the left"`
- `JetSprite-Right.imageset` — `"banking 15° to the right"`
- `JetSprite-Damaged.imageset` — `"with smoke trailing from the right wing"`

Mantén fondo transparente y silueta plana. Cada variante = su propio imageset, su propio `Contents.json` (copia el del jet base).

---

## Si prefieres hornearlo en el fondo

Alternativa: regenera `starfox-bg.png` con el avión ya incluido en la composición. Pierdes la posibilidad de animar el banking, pero la composición queda perfecta y no necesitas un sprite separado. En ese caso, ignora `JetSprite.imageset` y `JetSprite.swift`.
