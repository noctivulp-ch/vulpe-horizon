// Ajustes del agua. Porqué: docs/efectos/agua.md §Opciones
override agua_refraccion: i32 = 50;         // refracción de la superficie (0..100 %) (§1)
override agua_olas: f32 = 1.0;              // altura del oleaje (0..10) (§1)
override agua_velocidad: f32 = 1.0;         // velocidad del oleaje (0..5) (§1)
override agua_causticas: f32 = 1.0;         // brillo de las cáusticas (0..5) (§1)

// Opciones que pasaron a constantes con nombre resueltas por presets o mod nativo (§2.2 y §3)
const OPC_AGUA_CLARIDAD_DEFECTO: f32 = 1.0;
const OPC_AGUA_MINIMO: f32 = 1.0;           // brillo mínimo de la niebla bajo el agua
const OPC_AGUA_TEXTURA: bool = false;       // la textura vanilla del agua no se ve
const OPC_AGUA_F0: f32 = 0.02037;
const OPC_AGUA_CALMA: f32 = 0.30;           // escala mínima del oleaje en las zonas en calma (paridad/07 §2)
const OPC_AGUA_ESPECULAR_RUGOSIDAD: f32 = 0.07; // rugosidad efectiva del destello solar en olas
const OPC_AGUA_DISPERSION_CROMATICA: f32 = 0.25; // dispersión cromática de refracción (fino/07 §Ajustes)
const OPC_AGUA_VELOCIDAD_CASCADA: f32 = 1.8; // velocidad de descenso en caras verticales (fino/07 §1)
const OPC_AGUA_FRECUENCIA_ONDAS: f32 = 0.1;  // frecuencia nominal de ondas (paridad/07 §a)

struct OpcAgua {
    olas: AguOlas,
    claridad: f32,
    refraccion: f32,        // fracción de pantalla por unidad de normal tangente
}

fn opc_agua(tiempo: f32, lluvia: f32) -> OpcAgua {
    let mod_agua = opc_estilo_agua();
    return OpcAgua(
        AguOlas(agua_olas * (1.0 + 0.8 * lluvia), tiempo * agua_velocidad, OPC_AGUA_CALMA, agua_causticas * mod_agua.causticas_agudeza),
        OPC_AGUA_CLARIDAD_DEFECTO * mod_agua.claridad,
        f32(agua_refraccion) * 0.0006
    );
}

fn opc_agua_medio(claridad: f32) -> AguMedio {
    let mod_agua = opc_estilo_agua();
    let abs_mod = vec3<f32>(
        adp_mod_param(28u, 0.0, 1.0, VULPE_AGUA_ABSORCION_R, 0.35) / 0.35,
        adp_mod_param(29u, 0.0, 1.0, VULPE_AGUA_ABSORCION_G, 0.15) / 0.15,
        adp_mod_param(30u, 0.0, 1.0, VULPE_AGUA_ABSORCION_B, 0.05) / 0.05,
    );
    let turb_mod = adp_mod_param(31u, 0.0, 5.0, VULPE_AGUA_TURBIDEZ, 1.0);
    return agu_medio(claridad, mod_agua.absorcion * abs_mod, mod_agua.turbidez * turb_mod, mod_agua.color_disperso);
}
