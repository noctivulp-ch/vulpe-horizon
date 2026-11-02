// Ajustes de los rayos del fractal. Porqué: docs/efectos/rayos-del-fractal.md §Opciones
override rayos: bool = false;               // apagado por defecto, como en Vulpe
override rayos_intensidad: f32 = 200.0;

// Valores de Vulpe: de frente y de espaldas (especificación 14 §4).
const OPC_RAYOS_FOCO: vec2<f32> = vec2<f32>(85.0, 35.0);
const OPC_RAYOS_LONGITUD: vec2<f32> = vec2<f32>(70.0, 90.0);
const OPC_RAYOS_CAIDA: f32 = 96.0;
const OPC_RAYOS_UMBRAL: vec2<f32> = vec2<f32>(2.0, 4.0);
const OPC_RAYOS_NUCLEO: vec2<f32> = vec2<f32>(100.0, 40.0);
const OPC_RAYOS_ESPALDAS: f32 = 100.0;      // % de la intensidad de frente
const OPC_RAYOS_MUESTRAS: i32 = 32;
const OPC_RAYOS_OCLUSION: f32 = 60.0;
const OPC_RAYOS_ATRAS: f32 = 100.0;         // dispersión hacia atrás, %
