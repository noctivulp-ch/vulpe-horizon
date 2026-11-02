// Ajustes de la imagen final: exposición, bloom, tonos y gradación. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Opciones
override imagen_exposicion: f32 = 0.0;      // compensación en pasos (EV): −2…+2 = ×0,25…×4
override imagen_saturacion: f32 = 0.0;      // −1…+1
override imagen_contraste: f32 = 0.0;       // −1…+1
override imagen_tonemap: u32 = 2u;          // fílmico, ACES, Reinhard (por defecto: conserva el tono del cielo)
override imagen_tramado: bool = true;
override bloom_fuerza: f32 = 1.0;           // ×

// Constantes de la especificación 11 y 10 (no son opciones).
const OPC_EXPOSICION_K: f32 = 0.2;          // exposición = k / ln(L + 1 + c): E ≈ 3,2 de día (L ≈ 0,06)
const OPC_EXPOSICION_C: f32 = 0.002;        // tope en lo oscuro: k / ln(1 + c) ≈ 100
// Peso de la exposición automática frente a la previa analítica (en log): ver docs/efectos/
// exposicion-tonemap-gradacion.md §Exposición (duda para la especificación).
const OPC_EXPOSICION_PESO_AUTO: f32 = 0.5;
const OPC_ADAPTACION_SUBE: f32 = 1.5;       // s, hacia la luz
const OPC_ADAPTACION_BAJA: f32 = 4.0;       // s, hacia la oscuridad
const OPC_BASTONES_TAU: f32 = 10.0;         // s, la media lenta de los bastones
const OPC_BASTONES_L0: f32 = 0.0015;       // luminancia de escena a la que los bastones pesan la mitad
const OPC_PURKINJE: f32 = 1.0;
const OPC_BALANCE_K: f32 = 6500.0;
const OPC_NITIDEZ: f32 = 0.35;
const OPC_BLOOM: f32 = 0.08;                // fracción de la imagen desenfocada con fuerza 1
const OPC_BLOOM_NIEBLA: f32 = 1.0;
const OPC_BLOOM_NIEBLA_AGUA: f32 = 1.0;
const OPC_BLOOM_RADIO: f32 = 0.125;         // del alto de la pantalla

struct OpcImagen {
    compensacion: f32,      // multiplicador
    gradacion: ColParametrosGradacion,
    tonemap: u32,
    tramado: bool,
    bloom: f32,
}

fn opc_imagen() -> OpcImagen {
    return OpcImagen(
        exp2(imagen_exposicion),
        ColParametrosGradacion(0.0, 1.0 + imagen_saturacion, 1.0 + 0.5 * imagen_contraste),
        imagen_tonemap,
        imagen_tramado,
        bloom_fuerza * OPC_BLOOM,
    );
}
