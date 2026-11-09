// Ajustes de la lluvia y la nieve. Porqué: docs/efectos/lluvia-y-nieve.md §Opciones
const OPC_CLIMA_OPACIDAD_DEFECTO: f32 = 1.0;
const clima_opacidad: f32 = OPC_CLIMA_OPACIDAD_DEFECTO;

const OPC_LLUVIA_OPACIDAD: f32 = 0.5;      // paridad 16: calibrado para aclarar lo que tapa la gota (ver docs)
const OPC_NIEVE_OPACIDAD: f32 = 0.75;
const OPC_LLUVIA_ACLARADO: f32 = 2.0;      // la gota más clara que la luz que recibe: el original aclara ×1,2 lo de detrás
