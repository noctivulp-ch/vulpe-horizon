// Lectura y adaptación de los datos del mod nativo (formato v1, API 84).
// Porqué: docs/efectos/mod-nativo.md §Adaptador y ../vulpe-horizon-spec/flexibilidad/mod-nativo.md §5

const ADP_MOD_FIRMA_V1: f32 = 1001.0;

struct AdpRayoMod {
    posicion: vec3<f32>,    // relativa a la cámara en bloques
    edad: f32,              // segundos (negativa = sin rayo)
    activo: bool,           // bandera encendida y edad no negativa
}

struct AdpJugadorMod {
    salud: f32,             // 0..1
    tiempo_dano: f32,       // segundos desde el último daño
    en_llamas: f32,         // 0..1
    mojado: f32,            // 0..1
    activo: bool,           // bandera de estado del jugador encendida
}

struct AdpModDatos {
    activo: bool,           // firma 1001.0 presente
    version_tabla: u32,     // versión de la tabla de parámetros (1)
    banderas: u32,          // máscara de bits de cabecera
    ajustes_en_vivo: u32,   // número de ajustes en vivo en uso (0..16)

    tiene_tiempo: bool,     // bit 0: datos de tiempo válidos
    dia: f32,               // número de día acumulado (módulo 2^24)
    fase_luna: u32,         // 0..7 (0 = llena, 4 = nueva)

    tiene_estacion: bool,   // bit 2: estación continua válida
    estacion: f32,          // continua 0..4 (0 primavera, 1 verano, 2 otoño, 3 invierno)

    rayo: AdpRayoMod,       // bit 1
    jugador: AdpJugadorMod, // bit 3
}

fn adp_mod() -> AdpModDatos {
    // Si no está la firma del formato v1, todo vuelve a los valores por defecto (sin mod).
    let activo = abs(frame.mods[0].x - ADP_MOD_FIRMA_V1) < 0.5;
    if !activo {
        return AdpModDatos(
            false,
            0u,
            0u,
            0u,
            false,
            0.0,
            0u,
            false,
            0.0,
            AdpRayoMod(vec3<f32>(0.0), -1.0, false),
            AdpJugadorMod(1.0, 999.0, 0.0, 0.0, false),
        );
    }

    let version_tabla = u32(max(round(frame.mods[0].y), 0.0));
    let banderas = u32(max(round(frame.mods[0].z), 0.0));
    let ajustes_en_vivo = u32(clamp(round(frame.mods[0].w), 0.0, 16.0));

    // Bit 0: tiempo válido (día acumulado y fase lunar 0..7).
    let tiene_tiempo = (banderas & 1u) != 0u;
    let dia = select(0.0, max(frame.mods[1].x, 0.0), tiene_tiempo);
    let fase_luna = select(0u, u32(clamp(round(frame.mods[1].y), 0.0, 7.0)), tiene_tiempo);

    // Bit 2: estación continua válida (0 primavera .. 3 invierno, fracción = avance).
    let tiene_estacion = (banderas & 4u) != 0u;
    let estacion = select(0.0, clamp(frame.mods[1].z, 0.0, 4.0), tiene_estacion);

    // Bit 1: último rayo (posición relativa a la cámara y edad en segundos).
    let tiene_rayo = (banderas & 2u) != 0u;
    let edad_rayo = frame.mods[2].w;
    let rayo_activo = tiene_rayo && edad_rayo >= 0.0;
    let rayo = AdpRayoMod(frame.mods[2].xyz, edad_rayo, rayo_activo);

    // Bit 3: estado del jugador (salud, tiempo desde daño, fuego, humedad).
    let tiene_jugador = (banderas & 8u) != 0u;
    let jugador = AdpJugadorMod(
        clamp(frame.mods[3].x, 0.0, 1.0),
        max(frame.mods[3].y, 0.0),
        clamp(frame.mods[3].z, 0.0, 1.0),
        clamp(frame.mods[3].w, 0.0, 1.0),
        tiene_jugador,
    );

    return AdpModDatos(
        true,
        version_tabla,
        banderas,
        ajustes_en_vivo,
        tiene_tiempo,
        dia,
        fase_luna,
        tiene_estacion,
        estacion,
        rayo,
        jugador,
    );
}
