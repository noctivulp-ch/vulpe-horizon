// Ajustes de la vegetación ondulante. Porqué: docs/efectos/vegetacion-ondulante.md §Opciones
override ondulacion: bool = true;
override ondulacion_fuerza: f32 = 1.0;

const OPC_VIENTO_VELOCIDAD: f32 = 1.0;
// Medidos en paridad/15 (a cielo abierto, en seco): plantas 4,5 cm de media y 12 de máximo con periodo de 1,64 s;
// hojas lo mismo en horizontal, ±1,6 cm en vertical, periodo de 4,44 s. Amplitudes ajustadas a esas medias.
const OPC_VIENTO_PLANTA_PERIODO: f32 = 1.64;
const OPC_VIENTO_PLANTA_AMPLITUD: f32 = 0.0965;
const OPC_VIENTO_HOJA_PERIODO: f32 = 4.44;
const OPC_VIENTO_HOJA_AMPLITUD: f32 = 0.0558;
const OPC_VIENTO_HOJA_VERTICAL: f32 = 0.24;
const OPC_MAT_PLANTA_ALTA_ARRIBA: u32 = 8u;     // mitad superior de las plantas de dos bloques
