// ==========================================================================
// Constantes completas de vulpe-horizon (Canal fijo)
// ==========================================================================

const VULPE_PARAM_TABLE_VERSION: f32 = 1.0;
const VULPE_FIXED_CHANNEL_ACTIVE: bool = false;

// Brillo del cielo manual (rango: 0 .. 5, defecto: 1)
const VULPE_CIELO_BRILLO_MANUAL: f32 = 1.00000;

// Multiplicador de color del aire (canal rojo) (rango: 0 .. 2, defecto: 1)
const VULPE_AIRE_COLOR_R: f32 = 1.00000;

// Multiplicador de color del aire (canal verde) (rango: 0 .. 2, defecto: 1)
const VULPE_AIRE_COLOR_G: f32 = 1.00000;

// Multiplicador de color del aire (canal azul) (rango: 0 .. 2, defecto: 1)
const VULPE_AIRE_COLOR_B: f32 = 1.00000;

// Bruma de aerosoles (canal rojo) (rango: 0 .. 5, defecto: 1)
const VULPE_BRUMA_AEROSOLES_R: f32 = 1.00000;

// Bruma de aerosoles (canal verde) (rango: 0 .. 5, defecto: 1)
const VULPE_BRUMA_AEROSOLES_G: f32 = 1.00000;

// Bruma de aerosoles (canal azul) (rango: 0 .. 5, defecto: 1)
const VULPE_BRUMA_AEROSOLES_B: f32 = 1.00000;

// Asimetría de fase del halo solar (rango: 0 .. 1, defecto: 0.8)
const VULPE_HALO_ASIMETRIA: f32 = 0.80000;

// Intensidad luminosa del sol (rango: 0 .. 10, defecto: 1)
const VULPE_SOL_INTENSIDAD: f32 = 1.00000;

// Intensidad luminosa de la luna (rango: 0 .. 5, defecto: 1)
const VULPE_LUNA_INTENSIDAD: f32 = 1.00000;

// Modo manual del cielo fractal (0: auto, 1: manual) (rango: 0 .. 1, defecto: 0)
const VULPE_FRACTAL_MANUAL: f32 = 0.00000;

// Semilla base del dibujo fractal manual (rango: 0 .. 65535, defecto: 0)
const VULPE_FRACTAL_SEMILLA: f32 = 0.00000;

// Saturación de color del cielo fractal (rango: 0 .. 3, defecto: 1)
const VULPE_FRACTAL_SATURACION: f32 = 1.00000;

// Contraste tonal del cielo fractal (rango: 0 .. 3, defecto: 1)
const VULPE_FRACTAL_CONTRASTE: f32 = 1.00000;

// Frecuencia de repetición de la paleta fractal (rango: 0.5 .. 8, defecto: 1)
const VULPE_FRACTAL_CICLOS_PALETA: f32 = 1.00000;

// Brillo multiplicador de la luz ambiente (rango: 0 .. 5, defecto: 1)
const VULPE_LUZ_AMBIENTE_BRILLO: f32 = 1.00000;

// Iluminación mínima al aire libre (rango: 0 .. 1, defecto: 0.05)
const VULPE_LUZ_MINIMA_EXTERIOR: f32 = 0.05000;

// Intensidad de la luz de bloques (antorchas, etc.) (rango: 0 .. 5, defecto: 1)
const VULPE_LUZ_BLOQUE_INTENSIDAD: f32 = 1.00000;

// Habilita la modulación estacional del entorno (rango: 0 .. 1, defecto: 1)
const VULPE_ESTACIONES_ACTIVA: f32 = 1.00000;

// Duración de cada estación en días de juego (rango: 1 .. 120, defecto: 24)
const VULPE_ESTACION_DURACION_DIAS: f32 = 24.00000;

// Pasos de búsqueda para penumbra de sombras (rango: 1 .. 64, defecto: 16)
const VULPE_SOMBRAS_PROFUNDIDAD_BUSQUEDA: f32 = 16.00000;

// Teñido de sombras a través de vidrios de color (rango: 0 .. 1, defecto: 1)
const VULPE_SOMBRAS_TENIDO_TRANSLUCIDOS: f32 = 1.00000;

// Velocidad de disminución de la niebla con la altura (rango: 0 .. 1, defecto: 0.1)
const VULPE_NIEBLA_ALTURA_CAIDA: f32 = 0.10000;

// Altitud en bloques de la capa principal de nubes (rango: 50 .. 400, defecto: 192)
const VULPE_NUBES_ALTURA_CAPA1: f32 = 192.00000;

// Grosor volumétrico de la capa principal de nubes (rango: 10 .. 100, defecto: 32)
const VULPE_NUBES_ESPESOR_CAPA1: f32 = 32.00000;

// Radio de alcance de las cortinas de aurora (rango: 50 .. 1000, defecto: 300)
const VULPE_AURORA_RADIO: f32 = 300.00000;

// Opacidad y fuerza del velo de aurora (rango: 0 .. 5, defecto: 1)
const VULPE_AURORA_VELO: f32 = 1.00000;

// Longitud vertical de la cortina de aurora (rango: 0 .. 5, defecto: 1)
const VULPE_AURORA_CORTINA: f32 = 1.00000;

// Absorción espectral en agua (rojo) (rango: 0 .. 1, defecto: 0.35)
const VULPE_AGUA_ABSORCION_R: f32 = 0.35000;

// Absorción espectral en agua (verde) (rango: 0 .. 1, defecto: 0.15)
const VULPE_AGUA_ABSORCION_G: f32 = 0.15000;

// Absorción espectral en agua (azul) (rango: 0 .. 1, defecto: 0.05)
const VULPE_AGUA_ABSORCION_B: f32 = 0.05000;

// Turbidez y dispersión de partículas en agua (rango: 0 .. 5, defecto: 1)
const VULPE_AGUA_TURBIDEZ: f32 = 1.00000;

// Valor fijo de exposición cuando auto está apagado (rango: 0.05 .. 10, defecto: 1)
const VULPE_EXPOSICION_MANUAL: f32 = 1.00000;

// Velocidad de adaptación de la exposición automática (rango: 0.1 .. 10, defecto: 1)
const VULPE_ADAPTACION_VELOCIDAD: f32 = 1.00000;

// Temperatura de color del balance de blancos (Kelvin) (rango: 2000 .. 12000, defecto: 6500)
const VULPE_BALANCE_BLANCOS_K: f32 = 6500.00000;

// Concentración angular de los rayos crepusculares (rango: 0.1 .. 10, defecto: 1)
const VULPE_RAYOS_FOCO: f32 = 1.00000;

// Alcance espacial de los haces crepusculares (rango: 0.1 .. 5, defecto: 1)
const VULPE_RAYOS_LONGITUD: f32 = 1.00000;

// Atenuación con la distancia de los haces (rango: 0.1 .. 5, defecto: 1)
const VULPE_RAYOS_CAIDA: f32 = 1.00000;
