// Ajustes de la imagen final: exposición, bloom, tonos y gradación. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Opciones
override imagen_exposicion: f32 = 0.0;      // compensación en pasos (EV): −2…+2 = ×0,25…×4
override exposicion_oscuro: f32 = 0.0;      // pasos solo en lo oscuro (noche, cuevas): lo negra que es la noche
override exposicion_claro: f32 = 0.0;       // pasos solo en lo claro (día)
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
// Entre estas luminancias medias (escala común) se pasa del ajuste de lo oscuro al de lo claro, en log.
const OPC_EXPOSICION_L_OSCURO: f32 = 0.0003;
const OPC_EXPOSICION_L_CLARO: f32 = 0.03;
const OPC_ADAPTACION_SUBE: f32 = 1.5;       // s, hacia la luz
const OPC_ADAPTACION_BAJA: f32 = 4.0;       // s, hacia la oscuridad
const OPC_BASTONES_TAU: f32 = 10.0;         // s, la media lenta de los bastones
const OPC_BASTONES_L0: f32 = 0.0015;       // luminancia de escena a la que los bastones pesan la mitad
const OPC_PURKINJE: f32 = 1.0;
const OPC_BALANCE_K: f32 = 6500.0;
const OPC_NITIDEZ: f32 = 0.35;
const OPC_BLOOM: f32 = 0.3;                 // peso con que se suma el desenfoque con fuerza 1 (paridad 10), por la viñeta
const OPC_BLOOM_VINETA_CENTRO: f32 = 1.5;   // viñeta propia del bloom: ×1,5 en el centro (0,45)…
const OPC_BLOOM_VINETA_ESQUINA: f32 = 0.5;  // …y ×0,5 en las esquinas (0,15)
const OPC_BLOOM_NUCLEO: f32 = 0.75;         // parte del núcleo compacto en el desenfoque (el resto, el ancho)
const OPC_BLOOM_NIEBLA: f32 = 1.0;
const OPC_BLOOM_NIEBLA_AGUA: f32 = 1.0;
// Paridad 16: cada gota apaga el bloom de niebla en su píxel; sin máscara de gotas, se quita la parte que cubren (~10 %).
const OPC_BLOOM_NIEBLA_LLUVIA: f32 = -0.1;
const OPC_BLOOM_RADIO: f32 = 0.06;          // del alto de la pantalla (cola del halo; paridad 10: 97,6 % en 0,06)
const OPC_BLOOM_ANILLOS: i32 = 12;           // anillos del desenfoque ancho (las muestras por anillo salen del radio)
const OPC_BLOOM_ANILLOS_NIEBLA: i32 = 6;     // anillos del desenfoque de la niebla que pesa el bloom de niebla (es suave)

struct OpcImagen {
    compensacion: f32,      // multiplicador
    oscuro: f32,            // pasos en lo oscuro
    claro: f32,             // pasos en lo claro
    gradacion: ColParametrosGradacion,
    tonemap: u32,
    tramado: bool,
    bloom: f32,
}

fn opc_imagen() -> OpcImagen {
    return OpcImagen(
        exp2(imagen_exposicion),
        exposicion_oscuro,
        exposicion_claro,
        ColParametrosGradacion(0.0, 1.0 + imagen_saturacion, 1.0 + 0.5 * imagen_contraste),
        imagen_tonemap,
        imagen_tramado,
        bloom_fuerza * OPC_BLOOM,
    );
}
