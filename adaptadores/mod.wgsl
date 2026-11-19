// Lectura y adaptación de los datos del mod nativo (formatos 1, 2 y 3, API 84).
// Porqué: docs/efectos/mod-nativo.md §Adaptador y ../vulpe-horizon-spec/flexibilidad/mod-nativo.md §5

const ADP_MOD_FIRMA_V1: f32 = 1001.0;
const ADP_MOD_FIRMA_V2: f32 = 1002.0;   // formato 2: bioma de la cámara en mods[1].w (bit 5)
const ADP_MOD_FIRMA_V3: f32 = 1003.0;   // formato 3: estado de cristales en mods[6..7] (bit 8)

struct AdpCristalMod {
    activo: bool,           // formato 3, bit 8 (256)
    lluvia_pico: f32,       // 0..1 fuerza pico de lluvia/tormenta
    lluvia_secado: f32,     // 0..1 progreso del secado de 30 s tras parar
    escarcha: f32,          // 0..1 escarcha acumulada
    copos: f32,             // 0..1 copos pegados
    monton: f32,            // 0..1 montón de nieve abajo
    arena: f32,             // 0..1 arena acumulada
    nivel_lluvia: u32,      // 0 apagada, 1 ligera, 2 normal, 3 intensa
    nivel_nieve: u32,
    nivel_arena: u32,
    aliento_activo: bool,
    escarcha_interior: bool,
    arena_roja: bool,
    espectador: bool,
    bioma_seco: bool,
    bioma_frio: bool,
    viento_xz: vec2<f32>,   // dirección y fuerza normalizada [-1, 1] de 26
    vaho_pos: vec3<f32>,    // posición relativa a la cámara del último cristal cercano
    vaho_peso: f32,         // 0..1 peso suavizado del aliento (5 s)
}

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

    formato: u32,           // 1, 2 o 3
    tiene_bioma: bool,      // formato >= 2, bit 5
    bioma: u32,             // 0 desconocido, 1 pantano, 2 jungla, 3 jardín pálido
    bioma_peso: f32,        // 0..0,99, suavizado por el mod
    clima_particulas: bool, // formato >= 2, bit 7: la lluvia y la nieve las dibuja el mod como partículas (26)
    cristales: AdpCristalMod,
}

fn adp_cristal_mod_vacio() -> AdpCristalMod {
    return AdpCristalMod(
        false,
        0.0, 1.0,
        0.0, 0.0, 0.0, 0.0,
        2u, 2u, 2u,
        true, false, false, false, false, false,
        vec2<f32>(0.0),
        vec3<f32>(0.0), 0.0,
    );
}

fn adp_mod() -> AdpModDatos {
    // Sin la firma del formato 1, 2 o 3, todo vuelve a los valores por defecto (sin mod).
    let v3 = abs(frame.mods[0].x - ADP_MOD_FIRMA_V3) < 0.5;
    let v2 = v3 || abs(frame.mods[0].x - ADP_MOD_FIRMA_V2) < 0.5;
    let activo = v2 || abs(frame.mods[0].x - ADP_MOD_FIRMA_V1) < 0.5;
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
            0u,
            false,
            0u,
            0.0,
            false,
            adp_cristal_mod_vacio(),
        );
    }

    let version_tabla = u32(max(round(frame.mods[0].y), 0.0));
    let banderas = u32(max(round(frame.mods[0].z), 0.0));
    let tope_vivo = select(16.0, 8.0, v3);
    let ajustes_en_vivo = u32(clamp(round(frame.mods[0].w), 0.0, tope_vivo));

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

    // Formato 2, bit 5: categoría del bioma (parte entera) y su peso (parte decimal).
    let tiene_bioma = v2 && (banderas & 32u) != 0u;
    let w = max(frame.mods[1].w, 0.0);
    let bioma = select(0u, u32(floor(w)), tiene_bioma);
    let bioma_peso = select(0.0, fract(w), tiene_bioma);

    // Formato 3, bit 8: estado de «el tiempo en los cristales» (27) en mods[6] y mods[7].
    var cristales = adp_cristal_mod_vacio();
    if v3 && (banderas & 256u) != 0u {
        let m6 = frame.mods[6];
        let m7 = frame.mods[7];
        let c_lluvia = u32(max(round(m6.x), 0.0));
        let c_frio = u32(max(round(m6.y), 0.0));
        let c_arena = u32(max(round(m6.z), 0.0));
        let c_viento = u32(max(round(m6.w), 0.0));
        let flags12 = c_arena & 4095u;
        let vx = (f32(min(c_viento / 4096u, 4095u)) / 4095.0) * 2.0 - 1.0;
        let vz = (f32(c_viento & 4095u) / 4095.0) * 2.0 - 1.0;
        cristales = AdpCristalMod(
            true,
            f32(min(c_lluvia / 4096u, 4095u)) / 4095.0,
            f32(c_lluvia & 4095u) / 4095.0,
            f32(c_frio & 255u) / 255.0,
            f32((c_frio >> 8u) & 255u) / 255.0,
            f32((c_frio >> 16u) & 255u) / 255.0,
            f32(min(c_arena / 4096u, 4095u)) / 4095.0,
            flags12 & 3u,
            (flags12 >> 2u) & 3u,
            (flags12 >> 4u) & 3u,
            (flags12 & 64u) != 0u,
            (flags12 & 128u) != 0u,
            (flags12 & 256u) != 0u,
            (flags12 & 512u) != 0u,
            (flags12 & 1024u) != 0u,
            (flags12 & 2048u) != 0u,
            vec2<f32>(vx, vz),
            m7.xyz,
            clamp(m7.w, 0.0, 1.0),
        );
    }

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
        select(select(1u, 2u, v2), 3u, v3),
        tiene_bioma,
        bioma,
        bioma_peso,
        v2 && (banderas & 128u) != 0u,
        cristales,
    );
}

// Devuelve si las constantes fijas de `constantes_mod.wgsl` están activas y coinciden con la tabla v1.
fn adp_mod_fijo_valido() -> bool {
    return VULPE_FIXED_CHANNEL_ACTIVE && abs(VULPE_PARAM_TABLE_VERSION - 1.0) < 0.01;
}

// Busca un parámetro fino por su `id` (0..37) en los ajustes en vivo de `frame.mods[4..7]`;
// si no está en vivo, usa el valor del canal fijo si está activo; si no, usa el valor por defecto.
fn adp_mod_param(id: u32, min_val: f32, max_val: f32, fijo_val: f32, def_val: f32) -> f32 {
    let base = select(def_val, fijo_val, adp_mod_fijo_valido());
    let m = adp_mod();
    if !m.activo || m.version_tabla != 1u || m.ajustes_en_vivo == 0u {
        return base;
    }
    let tope = select(16u, 8u, m.formato >= 3u);
    let n = min(m.ajustes_en_vivo, tope);
    for (var i = 0u; i < n; i++) {
        let code_f = frame.mods[4u + (i / 4u)][i % 4u];
        if code_f >= 0.0 {
            let code = u32(round(code_f));
            if (code / 4096u) == id {
                let q = min(code % 4096u, 4095u);
                return min_val + (max_val - min_val) * (f32(q) / 4095.0);
            }
        }
    }
    return base;
}

// Vista de depuración del mod nativo (OPC_VISTA_MOD_NATIVO):
// Pinta en pantalla la firma (franja superior), fase lunar (franja central) y estación continua (franja inferior).
// También codifica en la esquina superior izquierda (uv < 0.04) los valores normalizados en RGB:
// R = 1.0 si firma presente, G = fase / 7.0, B = estacion / 4.0.
fn adp_mod_depuracion(uv: vec2<f32>) -> vec3<f32> {
    let m = adp_mod();

    // Cuadrado de lectura exacta por canal en la esquina superior izquierda
    if uv.x < 0.04 && uv.y < 0.04 {
        let r = select(0.0, 1.0, m.activo);
        let g = select(0.0, f32(m.fase_luna) / 7.0, m.tiene_tiempo);
        let b = select(0.0, m.estacion / 4.0, m.tiene_estacion);
        return vec3<f32>(r, g, b);
    }

    // 1. Franja superior (uv.y < 0.33): Firma y estado general del mod
    if uv.y < 0.33 {
        if !m.activo {
            // Sin mod nativo: fondo rojo de alarma con banda central oscura
            var rojo = vec3<f32>(0.75, 0.08, 0.08);
            if uv.y > 0.12 && uv.y < 0.21 {
                rojo = vec3<f32>(0.35, 0.02, 0.02);
            }
            return rojo;
        }

        // Mod activo (firma 1001.0 detectada): fondo verde esmeralda
        var verde = vec3<f32>(0.05, 0.50, 0.20);
        // Indicador central brillante si las banderas principales (tiempo + estación) están activas
        if uv.y > 0.08 && uv.y < 0.22 {
            let pleno = m.tiene_tiempo && m.tiene_estacion;
            verde = select(vec3<f32>(0.15, 0.75, 0.30), vec3<f32>(0.10, 0.95, 0.35), pleno);
        }

        // Subfranja de 5 casillas de banderas en la parte baja de la franja (0.24 < uv.y < 0.31)
        if uv.y > 0.24 && uv.y < 0.31 {
            let slot = u32(clamp(floor(uv.x * 5.0), 0.0, 4.0));
            let bit_activo = (m.banderas & (1u << slot)) != 0u;
            switch slot {
                case 0u: { // Bit 0: Tiempo (azul)
                    return select(vec3<f32>(0.05, 0.1, 0.2), vec3<f32>(0.2, 0.6, 1.0), bit_activo);
                }
                case 1u: { // Bit 1: Rayo (amarillo)
                    return select(vec3<f32>(0.15, 0.15, 0.05), vec3<f32>(1.0, 0.9, 0.2), bit_activo);
                }
                case 2u: { // Bit 2: Estación (verde)
                    return select(vec3<f32>(0.05, 0.15, 0.05), vec3<f32>(0.3, 1.0, 0.4), bit_activo);
                }
                case 3u: { // Bit 3: Jugador (rojo)
                    return select(vec3<f32>(0.15, 0.05, 0.05), vec3<f32>(1.0, 0.3, 0.3), bit_activo);
                }
                default: { // Bit 4: Canal fijo (púrpura)
                    let fijo_activo = bit_activo || (VULPE_FIXED_CHANNEL_ACTIVE && abs(VULPE_PARAM_TABLE_VERSION - 1.0) < 0.01);
                    return select(vec3<f32>(0.1, 0.05, 0.15), vec3<f32>(0.8, 0.3, 1.0), fijo_activo);
                }
            }
        }

        // Línea divisoria inferior
        if uv.y > 0.325 {
            return vec3<f32>(0.0);
        }
        return verde;
    }

    // 2. Franja central (0.33 <= uv.y < 0.66): Fase lunar (0..7 en 8 columnas)
    if uv.y < 0.66 {
        let col = u32(clamp(floor(uv.x * 8.0), 0.0, 7.0));
        let col_frac = fract(uv.x * 8.0);
        // Línea divisoria entre columnas y bordes
        if col_frac < 0.03 || col_frac > 0.97 || uv.y < 0.335 || uv.y > 0.655 {
            return vec3<f32>(0.02, 0.02, 0.03);
        }

        let es_fase_actual = (col == m.fase_luna) && m.tiene_tiempo;
        let factor_fase = abs(4.0 - f32(col)) / 4.0;

        if es_fase_actual {
            // Fase actual: columna iluminada con resplandor dorado lunar
            let dist_centro = length(vec2<f32>((col_frac - 0.5) * 2.0, (uv.y - 0.495) / 0.165));
            if dist_centro < 0.75 {
                // Disco lunar central
                return vec3<f32>(1.0, 0.98, 0.88);
            }
            return vec3<f32>(0.85, 0.80, 0.65) * (0.6 + 0.4 * factor_fase);
        }

        // Demás fases: fondo nocturno con brillo proporcional a la luminosidad de esa fase
        let brillo_inactivo = 0.06 + 0.15 * factor_fase;
        return vec3<f32>(0.08, 0.12, 0.22) * brillo_inactivo;
    }

    // 3. Franja inferior (uv.y >= 0.66): Estación continua (0..4)
    let estacion_norm = clamp(m.estacion / 4.0, 0.0, 1.0);
    let cuadrante = u32(clamp(floor(uv.x * 4.0), 0.0, 3.0));
    let quad_frac = fract(uv.x * 4.0);

    // Borde separador entre cuadrantes de estación
    if quad_frac < 0.015 || quad_frac > 0.985 || uv.y < 0.665 || uv.y > 0.995 {
        return vec3<f32>(0.02, 0.02, 0.03);
    }

    // Color base de cada estación
    var color_estacion: vec3<f32>;
    switch cuadrante {
        case 0u: { // Primavera (0..1): verde tierno / primaveral
            color_estacion = vec3<f32>(0.40, 0.88, 0.45);
        }
        case 1u: { // Verano (1..2): dorado cálido
            color_estacion = vec3<f32>(0.90, 0.82, 0.18);
        }
        case 2u: { // Otoño (2..3): naranja ámbar
            color_estacion = vec3<f32>(0.95, 0.48, 0.12);
        }
        default: { // Invierno (3..4): cian hielo
            color_estacion = vec3<f32>(0.45, 0.75, 0.98);
        }
    }

    // Aguja marcadora blanca de la estación exacta actual
    if m.tiene_estacion && abs(uv.x - estacion_norm) < 0.005 {
        return vec3<f32>(1.0, 1.0, 1.0);
    }

    // Progreso continuo: recorrido encendido, por recorrer tenue
    let recorrido = uv.x <= estacion_norm;
    let factor_avance = select(0.25, 1.0, recorrido && m.tiene_estacion);
    return color_estacion * factor_avance;
}

// El relámpago del mod (bit 1) como luz: sin mod, o pasado el destello, brillo 0. Porqué: docs/efectos/relampago.md
fn adp_relampago() -> LuzRelampago {
    let m = adp_mod();
    if !OPC_RELAMPAGO || !m.rayo.activo {
        return LuzRelampago(vec3<f32>(0.0), 0.0);
    }
    return LuzRelampago(m.rayo.posicion, luz_relampago_destello(m.rayo.edad, OPC_RELAMPAGO_DURACION));
}
