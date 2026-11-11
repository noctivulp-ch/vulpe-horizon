// Ajustes de la imagen final: exposición, bloom, tonos y gradación. Porqué: docs/efectos/exposicion-tonemap-gradacion.md §Opciones
override exposicion_auto: bool = true;      // exposición automática sí/no (§1)
override exposicion: f32 = 1.0;             // multiplicador de la exposición (0,25..4) (§1)
override curva_tonos: u32 = 0u;             // curva de mapeo de tonos: Fílmico (Hejl 2015), ACES, Reinhard (§1)
override saturacion: f32 = 0.0;             // saturación sumada al estilo de color (−1..1) (§1)
override nitidez: f32 = 0.35;               // nitidez posterior (0..1) (§1)
override desenfoque_movimiento: i32 = 0;    // desenfoque de movimiento (0..100) (§1)
override bloom_fuerza: f32 = 1.0;           // fuerza del bloom (0..10) (§1)
override bloom_niebla: f32 = 1.0;           // bloom de niebla, agua y lluvia (0..20) (§1)

// Opciones que pasaron a constantes con nombre resueltas por presets o mod nativo (§2.2 y §3)
const OPC_EXPOSICION_OSCURO_DEFECTO: f32 = 0.0; // pasos solo en lo oscuro (noche, cuevas)
const OPC_EXPOSICION_CLARO_DEFECTO: f32 = 0.0;  // pasos solo en lo claro (día)
const OPC_IMAGEN_CONTRASTE_DEFECTO: f32 = 0.0;
const OPC_IMAGEN_TRAMADO_DEFECTO: bool = true;

// Constantes de la especificación 11 y 10 (no son opciones).
const OPC_EXPOSICION_K: f32 = 0.2;          // exposición = k / ln(L + 1 + c): E ≈ 3,2 de día (L ≈ 0,06)
const OPC_EXPOSICION_C: f32 = 0.002;        // tope en lo oscuro: k / ln(1 + c) ≈ 100
// Peso de la exposición automática frente a la previa analítica (en log): ver docs/efectos/
// exposicion-tonemap-gradacion.md §Exposición (duda para la especificación).
const OPC_EXPOSICION_PESO_AUTO: f32 = 1.0;
// Entre estas luminancias medias (escala común) se pasa del ajuste de lo oscuro al de lo claro, en log.
const OPC_EXPOSICION_L_OSCURO: f32 = 0.0003;
const OPC_EXPOSICION_L_CLARO: f32 = 0.03;
const OPC_ADAPTACION_SUBE: f32 = 0.33;      // s: peso 0,95 por fotograma a 60 fps del original (fino/11 §Medidos 4–5; F-7)
const OPC_ADAPTACION_BAJA: f32 = 0.33;      // s: el original adapta la medida al mismo ritmo en los dos sentidos
const OPC_BASTONES_TAU: f32 = 1.1;          // s: peso 0,985 por fotograma (3,3 veces más lenta que los conos)
const OPC_BASTONES_L0: f32 = 0.0015;       // luminancia de escena a la que los bastones pesan la mitad
const OPC_PURKINJE: f32 = 1.0;
const OPC_BALANCE_K: f32 = 6500.0;
const OPC_FILMICO_BLANCO: f32 = 3.1;       // punto blanco del fílmico de Hejl 2015 (paridad/11)
// Exposición propia de cada curva (fílmico, ACES, Reinhard): el fílmico da más en los medios tonos; con ×0,5 deja el día
// y la noche donde los dejaba Reinhard y el cielo azul (lo que le llegaba a la curva venía demasiado expuesto).
const OPC_TONEMAP_EXPOSICION = array<f32, 3>(1.0, 1.0, 1.0);
const OPC_BLOOM: f32 = 0.3;                 // peso con que se suma el desenfoque con fuerza 1 (paridad 10), por la viñeta
const OPC_BLOOM_VINETA_CENTRO: f32 = 1.5;   // viñeta propia del bloom: ×1,5 en el centro (0,45)…
const OPC_BLOOM_VINETA_ESQUINA: f32 = 0.5;  // …y ×0,5 en las esquinas (0,15)
const OPC_BLOOM_ENERGIA: f32 = 0.9379;      // energía total del desenfoque ponderado del original (paridad/10)
const OPC_BLOOM_NUCLEO: f32 = 0.75;         // parte del núcleo compacto en el desenfoque (el resto, el ancho)
const OPC_BLOOM_NIEBLA_AGUA: f32 = 1.0;
// Paridad 16: cada gota apaga el bloom de niebla en su píxel; sin máscara de gotas, se quita la parte que cubren (~10 %).
const OPC_BLOOM_NIEBLA_LLUVIA: f32 = -0.1;
const OPC_BLOOM_RADIO: f32 = 0.06;          // del alto de la pantalla (cola del halo; paridad 10: 97,6 % en 0,06)
const OPC_BLOOM_ANILLOS: i32 = 12;           // anillos del desenfoque ancho (las muestras por anillo salen del radio)
const OPC_BLOOM_NIEBLA_NUCLEO: f32 = 0.3;    // parte compacta del desenfoque de niebla (paridad/10: su pico es 0,38 del ponderado)

struct OpcImagen {
    compensacion: f32,      // multiplicador
    oscuro: f32,            // pasos en lo oscuro
    claro: f32,             // pasos en lo claro
    gradacion: ColParametrosGradacion,
    tonemap: u32,
    tramado: bool,
    bloom: f32,
}

fn opc_balance_k() -> f32 {
    let k_mod = adp_mod_param(34u, 2000.0, 12000.0, VULPE_BALANCE_BLANCOS_K, 6500.0) - 6500.0;
    return clamp(opc_estilo_color().balance_k + k_mod, 2000.0, 12000.0);
}

fn opc_imagen() -> OpcImagen {
    let mod_color = opc_estilo_color();
    let sat_final = 1.0 + mod_color.saturacion + saturacion;
    let cont_final = (1.0 + 0.5 * OPC_IMAGEN_CONTRASTE_DEFECTO) * mod_color.contraste;
    let exp_man = adp_mod_param(32u, 0.05, 10.0, VULPE_EXPOSICION_MANUAL, 1.0);
    let comp = select(exposicion * exp_man, exposicion, exposicion_auto);
    return OpcImagen(
        comp,
        OPC_EXPOSICION_OSCURO_DEFECTO,
        OPC_EXPOSICION_CLARO_DEFECTO,
        ColParametrosGradacion(0.0, sat_final, cont_final),
        curva_tonos,
        OPC_IMAGEN_TRAMADO_DEFECTO,
        bloom_fuerza * OPC_BLOOM,
    );
}
