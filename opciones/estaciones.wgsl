// Ajustes de las estaciones. Porqué: docs/efectos/luz-de-superficie.md §Estaciones
const OPC_ESTACIONES_DEFECTO: bool = true;
const OPC_ESTACION_INICIAL_DEFECTO: u32 = 0u;        // verano, otoño, invierno, primavera

const estaciones: bool = OPC_ESTACIONES_DEFECTO;
const estacion_inicial: u32 = OPC_ESTACION_INICIAL_DEFECTO;

const OPC_ESTACION_DIAS: f32 = 24.0;
