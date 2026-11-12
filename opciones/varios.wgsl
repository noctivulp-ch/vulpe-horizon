// Ajustes varios del subsistema 24, apagados por defecto: constantes sin opción de menú (64/64).
// Porqué: docs/efectos/varios.md
const OPC_OCLUSION_MATERIAL: bool = false;  // oscurecer el albedo con la oclusión del mapa de normales LabPBR (½..1)
const OPC_CURVATURA: f32 = 0.0;             // curvatura del mundo (−100..100): a 128 bloques baja 0,1 por punto
const OPC_OLAS_VERTICE: f32 = 0.0;          // olas grandes en los vértices del agua (0..1)
const OPC_INFRARROJO: f32 = 0.0;            // modo infrarrojo: cuánto rosa en la vegetación (0..1)
const OPC_INFRARROJO_LANA: bool = false;    // también la lana: sin efecto hasta etiquetarla (ver docs)
const OPC_INFRARROJO_COLOR: vec3<f32> = vec3<f32>(1.0, 0.32, 0.45);
