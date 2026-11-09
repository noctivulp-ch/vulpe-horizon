# Guía técnica de Vulpe para Horizon

Guía técnica del shader [Vulpe](https://github.com/noctivulp-ch/vulpe-horizon) para el motor [Horizon](https://github.com/horizon-rust/horizon).
Describe la arquitectura interna, la metodología de desarrollo en sala limpia, cómo compilar e instalar desde el código fuente y las herramientas de validación.

---

## Cómo está hecho

Vulpe para Horizon no es un port directo ni una conversión de un shader de Iris u OptiFine: está escrito desde cero en WGSL para la API nativa de shaders de Horizon.

### Metodología de sala limpia

La versión original de Vulpe se apoya en Bliss, cuya licencia no permite publicar trabajos derivados. Para garantizar total independencia y respeto de las licencias, esta versión se escribió bajo una metodología estricta de **sala limpia** con dos agentes separados por una especificación funcional:

- **Agente A (analista/especificador):** analizó el comportamiento del shader original y describió funcionalmente qué hace cada parte mediante fórmulas matemáticas públicas y tablas de referencia, sin trasladar código.
- **Agente B (implementador):** escribió este pack únicamente a partir de esa especificación funcional y de la bibliografía pública.
- **Gestor:** supervisó la muralla de sala limpia, comprobó que ningún lote infringiera las reglas y realizó las pruebas visuales en el motor.

Para consultar los principios detallados y las decisiones tomadas:
- Metodología completa: [`docs/metodologia.md`](metodologia.md)
- Registro de decisión: [ADR 0001 — Desarrollo en sala limpia](decisiones/0001-sala-limpia.md)

### Carpetas por función y principios SOLID

La estructura del repositorio organiza el código según la función de cada archivo, aplicando una separación estricta de responsabilidades:

- `etapas/`: puntos de entrada de cada etapa del pipeline gráfico de Horizon (`sky`, `material`, `vertex`, `weather`, `displacement`) y las 7 pasadas `post` en orden secuencial. Solo componen el flujo de ejecución delegando el trabajo.
- `nucleo/`: funciones matemáticas y físicas puras, independientes del motor y sin acceso directo a las estructuras de `frame`. Organizado en:
  - `matematica/`: proyecciones, matrices y utilidades numéricas.
  - `ruido/`: funciones de ruido procedural, hash y muestreo blue noise.
  - `color/`: espacios de color, tonemapping, virados y balance fílmico.
  - `atmosfera/`: dispersión física Rayleigh y Mie, transmitancia y tablas solares.
  - `cielo/`: sol, luna, estrellas, cinturón de Venus y cielo fractal (Mandelbrot y Julia).
  - `volumen/`: raymarching volumétrico de atmósfera, nubes de varias capas, niebla y auroras fractales.
  - `superficie/`: modelo LabPBR, reflectancia GGX, SSS en hojas/nieve, charcos y relieve geométrico.
  - `luz/`: cálculo de luz difusa, luz de bloque, sombras PCSS y cáusticas.
  - `imagen/`: anti-aliasing temporal (TAA), FXAA, bloom, exposición automática y oclusión ambiental (GTAO/AO).
- `adaptadores/`: la única capa que interactúa con la API de Horizon (`frame`, `MaterialInput`, `DisplacementInput`), transformando los datos del motor en parámetros para el núcleo.
- `opciones/`: constantes con nombre y valores por defecto correspondientes a las opciones del menú definidas en `horizon-shaders.toml`.
- `tools/`: herramientas para montar, validar y probar el shader mediante `horizon-ctl`.

| Capa | Qué hay | Responsabilidad |
|---|---|---|
| `etapas/` | Puntos de entrada de cada etapa y pasadas `post` | Composición y orden de renderizado |
| `nucleo/` | Matemática, ruido, color, atmósfera, cielo, volumen, superficie, luz e imagen | Algoritmos y cálculos puros sin dependencias de API |
| `adaptadores/` | Traducción de la API de Horizon (`frame`, `MaterialInput`…) al núcleo | Interfaz con el motor |
| `opciones/` | Ajustes de menú y constantes con nombre por subsistema | Configuración y calibración |
| `tools/` | Montar, validar, empaquetar y controlar escenas con `horizon-ctl` | Herramientas del flujo de trabajo |

Decisiones de diseño asociadas:
- [ADR 0002 — Estructura de carpetas por función](decisiones/0002-estructura-por-funcion.md)
- [ADR 0003 — Empaquetado del pack montado en build](decisiones/0003-pack-montado-en-build.md)
- [ADR 0004 — Codificación del picture buffer](decisiones/0004-codificacion-del-picture.md)

---

## Compilación e instalación desde el código (desarrollo)

Para colaborar en el desarrollo o probar cambios en local, el pack se compila y monta directamente desde este repositorio.

### Requisitos

- **Horizon** instalado con su lanzador ([instrucciones en su repositorio](https://github.com/horizon-rust/horizon)).
- Se recomienda una compilación *nightly* compatible (probado con `nightly-2026-11-08-fdc87ae`). Las etapas `vertex` y `displacement` requieren compilaciones posteriores al 2026-11-01.

### 1. Clonar el repositorio y montar el pack

```bash
git clone https://github.com/noctivulp-ch/vulpe-horizon.git
cd vulpe-horizon
./tools/montar.sh
```

El script `tools/montar.sh` ensambla los archivos de las distintas carpetas y genera el pack montado en `build/vulpe/`.

### 2. Validar los shaders

Antes de ejecutar el pack, valida que no haya errores de compilación de WGSL ni discrepancias en las firmas de las etapas:

```bash
./tools/validar.sh
```

### 3. Probar en el juego

Existen tres formas de utilizar el pack montado:

1. **Copia a la carpeta de shaderpacks:**
   Copia la carpeta montada `build/vulpe/` dentro de la carpeta `shaderpacks/` de tu instancia de Horizon (junto a `options.txt`) y selecciona el pack en el menú de shaders del juego.
2. **Empaquetado `.hshader`:**
   Ejecuta `tools/empaquetar.sh` para generar el archivo comprimido en `dist/` e instálalo con el lanzador:
   ```bash
   ./tools/empaquetar.sh
   horizon-launcher packs add dist/vulpe-*.hshader
   ```
3. **Iteración en vivo (recarga en caliente):**
   Inicia Horizon con la variable de entorno del pack apuntando al directorio montado:
   ```bash
   HORIZON_SHADER_PACK=build/vulpe horizon
   ```
   Horizon recargará automáticamente los shaders al guardar cualquier cambio en los archivos de `build/vulpe/`.

---

## Documentación adicional

- [`docs/index.md`](index.md): índice general de documentación.
- [`docs/metodologia.md`](metodologia.md): protocolo de trabajo, medición y criterios de calidad.
- [`docs/decisiones/`](decisiones/): registro de decisiones de arquitectura (ADR).
- [`docs/efectos/`](efectos/): especificaciones y fundamentos teóricos de cada efecto visual.
