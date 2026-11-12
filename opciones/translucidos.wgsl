// Ajustes de los translúcidos que no son agua (22): cristal tintado, hielo, slime, miel. Sin opción de menú (64/64):
// constantes. Porqué: docs/efectos/translucidos.md

const OPC_TRANSL_TINTE: bool = true;            // tinte multiplicativo de lo de detrás (§Tinte)
const OPC_TRANSL_TINTE_MIN: f32 = 0.1;          // opacidad por debajo de la cual el tinte se va a cero (§Tinte)
// Fuerza de la refracción (0..100, como la del agua; la dispersión es la del agua, 50) (§Refracción)
const OPC_TRANSL_REFRACCION: f32 = 50.0;
const OPC_TRANSL_F0: f32 = 0.02;                // reflectancia a incidencia normal sin datos de material (§Reflejos)
