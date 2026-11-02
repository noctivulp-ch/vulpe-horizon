# 0002 — Carpetas por función y SOLID en WGSL

**Fecha:** 2026-11-01 · **Estado:** aceptada · **Pedido del usuario:** «necesito que el shader resultante,
además de principios SOLID, separe cada clase/archivo en carpetas que se nombren y ordenen por función».

## Contexto

WGSL no tiene clases, módulos ni `#include`: Horizon arma cada etapa concatenando los archivos que el
manifiesto le nombra (`shared`, y `files` por etapa). Las «clases» son aquí **familias de funciones y sus
structs**, una por archivo.

## Estructura

```
vulpe-horizon/
├── horizon-shaders.toml        manifiesto: etapas, opciones, materiales, páginas del menú
├── etapas/                     SOLO puntos de entrada: componen, no calculan
│   ├── cielo.wgsl              fn sky
│   ├── material.wgsl           fn material
│   ├── vertice.wgsl            fn vertex
│   ├── clima.wgsl              fn weather
│   └── post/                   una pasada por archivo, numeradas en el orden en que corren
│       ├── 01-volumen.wgsl
│       └── …
├── nucleo/                     funciones puras: no leen `frame` ni recursos del motor
│   ├── matematica/             constantes, proyecciones, espacios, utilidades
│   ├── ruido/                  hash, ruido de valor/gradiente, fBm
│   ├── color/                  espacios de color, luminancia, tonemap, gradación
│   ├── atmosfera/              dispersión Rayleigh/Mie, astros
│   ├── cielo/                  fractal, estrellas, mapas del cielo
│   ├── volumen/                densidad, fase, raymarch de niebla y nubes, aurora
│   ├── superficie/             BRDF, PBR, SSS, emisión, menas, agua
│   ├── luz/                    sombras, difusa, oclusión ambiental
│   └── imagen/                 TAA, bloom, filtros, aislamiento de color, rayos
├── adaptadores/                traducen la API de Horizon (frame, MaterialInput, PostInput…) a los
│                               parámetros del núcleo: el único sitio que conoce la API
├── opciones/                   lectura de los `override` agrupada por efecto (structs de ajustes)
├── pruebas/                    escenas y guiones de horizon-ctl para comprobar cada módulo
├── tools/                      validar, empaquetar, probar en el juego
└── docs/                       decisiones, efectos/<efecto>.md («Por qué del código»), observaciones
```

## SOLID, traducido a WGSL

- **S — una responsabilidad por archivo.** Un archivo = una familia de funciones con un propósito
  (p. ej. `nucleo/atmosfera/dispersion.wgsl`). Si para describirlo hace falta «y», son dos archivos.
- **O — abierto a extensión.** Un efecto nuevo es archivos nuevos y líneas en el manifiesto; no se
  reescriben los existentes. Las etapas solo componen.
- **L — implementaciones intercambiables.** Variantes de una misma pieza (dos modelos de niebla, dos
  tonemaps) comparten firma y struct de entrada, y se eligen por opción en el adaptador.
- **I — interfaces pequeñas.** Cada función del núcleo recibe un struct propio con solo lo que necesita
  (`ParametrosNiebla`, `Rayo`…), nunca el `frame` entero.
- **D — dependencias invertidas.** El núcleo no depende de Horizon; los adaptadores dependen del núcleo y
  de la API. Así el núcleo se puede llevar a otro motor (base neutra: ver
  `../vulpe-forged/docs/analisis/horizon.md`).

## Convenciones

- **Sin espacios de nombres en WGSL:** cada función lleva el prefijo de su carpeta y archivo
  (`atm_rayleigh`, `vol_densidad_niebla`, `img_taa_mezcla`).
- **Orden de concatenación = orden de dependencias:** `matematica` → `ruido` → `color` → el resto del
  núcleo → `opciones` → `adaptadores` → la etapa. El manifiesto lo refleja.
- **El porqué va en `docs/efectos/<efecto>.md`;** el código lleva solo una línea de guía que remite allí.
