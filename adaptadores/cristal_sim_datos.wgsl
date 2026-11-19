// Constantes de disposición del buffer `cristal_sim` (2705 vec4<f32> = 43 280 bytes).
// Compartido entre `cristal_sim` (escritura), `cristal_lienzo` (lectura), `cristal_mapa` y `03-composicion`.
// Porqué: docs/efectos/tiempo-en-los-cristales.md §2

const ADP_CS_MAX_GOTAS_LADO: u32 = 110u;
const ADP_CS_SLOT_LADO: u32 = 112u;
const ADP_CS_MAX_GOTAS_ARRIBA: u32 = 80u;
const ADP_CS_MAX_COPOS: u32 = 140u;
const ADP_CS_SLOT_COPOS: u32 = 144u;
const ADP_CS_OFF_LADO: u32 = 16u;
const ADP_CS_OFF_ARRIBA: u32 = 912u;
const ADP_CS_OFF_COPOS: u32 = 1552u;
const ADP_CS_RESUMEN: u32 = 2704u; // x: hay cristal transparente en caché (0/1)
