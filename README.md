<div align="center">

# Vulpe para Horizon

**Shader para [Horizon](https://github.com/horizon-rust/horizon), el Minecraft Java 26.3 reescrito en Rust: cielo físico, cielo fractal con aurora, niebla volumétrica, agua y luz PBR.**

![Licencia](https://img.shields.io/badge/licencia-GPL--3.0--or--later-FF6B00?style=flat-square&labelColor=1A1A1A)
![Motor](https://img.shields.io/badge/motor-Horizon-3A3A3A?style=flat-square&labelColor=1A1A1A)
![WGSL](https://img.shields.io/badge/WGSL-API%20de%20shaders%200.1-3A3A3A?style=flat-square&labelColor=1A1A1A)
![Estado](https://img.shields.io/badge/estado-en%20desarrollo-FF6B00?style=flat-square&labelColor=1A1A1A)

</div>

---

## Qué es

Vulpe es un shader para [Horizon](https://github.com/horizon-rust/horizon) con aspecto propio: cielo con dispersión atmosférica real, cielo fractal con aurora que ilumina la niebla volumétrica, agua con refracción y cáusticas, y luz PBR completa. Está escrito desde cero en WGSL para la API nativa de Horizon, con su propio motor por etapas y pasadas de postprocesado.

Está **inspirado en [Bliss](https://github.com/X0nk/Bliss-Shader)**, el shader de X0nk para Iris y OptiFine en el que se basa la versión original de Vulpe. No reutiliza su código: se escribió en sala limpia, a partir de una especificación de su comportamiento ([`docs/metodologia.md`](docs/metodologia.md)).

La idea del cielo fractal nocturno viene de la opción «Fractal Night Sky» de [rethinking-voxels](https://github.com/gri573/rethinking-voxels) (gri573); el código es propio.

<p align="center">
  <img src="pruebas/capturas/hoja-imagen.png" width="90%" alt="Día, atardecer, noche con aurora y cueva en Vulpe para Horizon">
</p>

## Funciones principales

- **Cielo y atmósfera:** dispersión física Rayleigh y Mie, sol, luna, estrellas y cinturón de Venus.
- **Cielo fractal y aurora:** figuras de Julia y Mandelbrot que cambian cada noche y emiten cortinas de luz sobre la niebla.
- **Niebla y nubes:** raymarch volumétrico unificado con horario de niebla y tres capas dinámicas de nubes.
- **Luz y materiales:** iluminación difusa y GGX, soporte LabPBR completo, SSS en hojas y nieve, charcos y relieve geométrico.
- **Sombras:** PCSS con penumbra variable, sombras coloreadas de cristal y agua, y sombras de nubes.
- **Agua:** olas, refracción profunda, absorción, cáusticas submarinas y niebla bajo el agua con ventana de Snell.
- **Postprocesado:** TAA con FXAA, bloom, autoexposición, tonemapping fílmico y oclusión ambiental.
- **Propias de Vulpe:** menas brillantes en la roca, aislamiento de color configurable y adaptación para Nether y End.

## Instalación

1. Descarga el paquete `.hshader` desde **[Releases](https://github.com/noctivulp-ch/vulpe-horizon/releases)**.
2. Instálalo con `horizon-launcher packs add vulpe-0.2.0-beta.1.hshader` (o cópialo en la carpeta `shaderpacks/`).
3. Actívalo en el menú de shaders del juego. Para compilar desde el código fuente, consulta [`docs/guia.md`](docs/guia.md).

## Progreso

| Fase | Descripción | Estado |
|---|---|---|
| 1. Base | 16 subsistemas iniciales especificados e implementados | **Hecha** |
| 2. Faltas | Ajustes frente al original y correcciones visuales | **Hecha** |
| 3. Paridad | Medición contra tablas de referencia y escenas fijas | **En curso** |
| 4. Flexibilidad | Presets de calidad y estilo (64 opciones) y mod nativo | **Hecha** |
| 5. Beta pública | Primera versión empaquetada (`.hshader`) | **Hecha** |
| 6. Detalles finos | Rendimiento, pulido de rincones y ajustes finales | Pendiente |

## Licencia

Código bajo **GPL-3.0-or-later** ([`LICENSE`](LICENSE)). Los componentes de terceros y sus licencias
están en [`NOTICE`](NOTICE). El nombre y la identidad visual no forman parte de la licencia: ver
[`TRADEMARKS.md`](TRADEMARKS.md). Para aportar, [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Apoyo

Este proyecto forma parte del trabajo de **NoctiVulp**: herramientas para Linux y Android,
publicadas como software libre. Las compilaciones oficiales y las novedades salen en Patreon.

<p align="center">
  <a href="https://www.patreon.com/cw/NoctiVulp"><img src="https://img.shields.io/badge/Patreon-NoctiVulp-FF6B00?style=for-the-badge&logo=patreon&logoColor=white&labelColor=1A1A1A" alt="NoctiVulp en Patreon"></a>
</p>

---

<p align="center"><sub>© 2026 NoctiVulp · <b>Powered by AI</b> — desarrollado con la asistencia de Claude, de Anthropic.</sub></p>
