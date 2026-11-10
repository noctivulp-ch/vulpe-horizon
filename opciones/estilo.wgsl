// Ajustes de los presets de estilo (§2.2). Porqué: docs/efectos/estilo.md §Presets de estilo

override estilo_cielo: u32 = 0u;
override estilo_niebla_horaria: u32 = 1u;
override estilo_tiempo: u32 = 0u;
override estilo_biomas: u32 = 0u;
override estilo_color: u32 = 0u;
override efectos_camara: u32 = 0u;
override profundidad_campo: u32 = 0u;
override estilo_agua: u32 = 0u;
override estilo_luz_bloque: u32 = 0u;
override estilo_noches: u32 = 0u;
override estilo_fractal: u32 = 0u;
override estilo_aurora: u32 = 1u;
override estilo_rayos: u32 = 1u;
override efectos_juego: u32 = 2u;
override atmosfera_nether: u32 = 1u;
override tormenta_end: u32 = 1u;
override estilo_cuevas: u32 = 1u;

// 1. Cielo: natural (defecto), limpio, brumoso, atardeceres intensos
struct OpcModifCielo {
    aire: f32,
    aerosoles: f32,
    asimetria: f32,
    brillo: f32,
}

fn opc_estilo_cielo() -> OpcModifCielo {
    switch estilo_cielo {
        case 1u: { // Limpio: aerosoles ×0,5, halo más estrecho
            return OpcModifCielo(1.0, 0.5, 0.85, 1.0);
        }
        case 2u: { // Brumoso: aerosoles ×2, halo más ancho
            return OpcModifCielo(1.0, 2.0, 0.72, 1.0);
        }
        case 3u: { // Atardeceres intensos: aire ×1,3, aerosoles ×1,5
            return OpcModifCielo(1.3, 1.5, 0.8, 1.15);
        }
        default: { // Natural (por defecto)
            return OpcModifCielo(1.0, 1.0, 0.8, 1.0);
        }
    }
}

// 2. Niebla horaria: despejada, por defecto, brumosa, noches cerradas
struct OpcModifNieblaHoraria {
    mult_dia: f32,
    mult_noche: f32,
    mult_manchas_dia: f32,
    mult_manchas_noche: f32,
    niebla_lluvia: f32,
}

fn opc_estilo_niebla_horaria() -> OpcModifNieblaHoraria {
    switch estilo_niebla_horaria {
        case 0u: { // Despejada: todo ×0,4
            return OpcModifNieblaHoraria(0.4, 0.4, 0.4, 0.4, 0.4);
        }
        case 2u: { // Brumosa: ×2 de día, ×1,3 de noche
            return OpcModifNieblaHoraria(2.0, 1.3, 2.0, 1.3, 1.5);
        }
        case 3u: { // Noches cerradas: de día igual, de noche ×1,8 la uniforme y ×3 en manchas
            return OpcModifNieblaHoraria(1.0, 1.8, 1.0, 3.0, 1.0);
        }
        default: { // Por defecto
            return OpcModifNieblaHoraria(1.0, 1.0, 1.0, 1.0, 1.0);
        }
    }
}

// 3. Tiempo diario: los del pack (defecto), despejado, variable, encapotado, tormentoso
struct OpcModifTiempo {
    mult_cobertura: f32,
    mult_densidad: f32,
    densidad_lluvia: f32,
}

fn opc_estilo_tiempo() -> OpcModifTiempo {
    switch estilo_tiempo {
        case 1u: { // Despejado: cobertura ×0,5
            return OpcModifTiempo(0.5, 1.0, 1.0);
        }
        case 2u: { // Variable: ×1, perfiles más diferenciados
            return OpcModifTiempo(1.0, 1.0, 1.0);
        }
        case 3u: { // Encapotado: cobertura ×1,5
            return OpcModifTiempo(1.5, 1.0, 1.0);
        }
        case 4u: { // Tormentoso: cobertura ×1,5 y densidad ×1,5 con lluvia
            return OpcModifTiempo(1.5, 1.2, 1.5);
        }
        default: { // Los del pack (por defecto)
            return OpcModifTiempo(1.0, 1.0, 1.0);
        }
    }
}

// 4. Biomas: apagado (defecto), sutil, marcado (pendiente de datos de biomas)
fn opc_estilo_biomas() -> u32 {
    return estilo_biomas;
}

// 5. Estilo de color y gradación: neutro (defecto), cálido, frío, cine, vivo
struct OpcModifColor {
    balance_k: f32,
    saturacion: f32,
    diafonia: f32,
    tinte_sombras: vec3<f32>,
    tinte_luces: vec3<f32>,
    contraste: f32,
}

fn opc_estilo_color() -> OpcModifColor {
    switch estilo_color {
        case 1u: { // Cálido: 5500 K, luces algo más rojas
            return OpcModifColor(5500.0, 0.0, 0.0, vec3<f32>(1.0, 0.98, 0.95), vec3<f32>(1.05, 0.98, 0.92), 1.0);
        }
        case 2u: { // Frío: 7500 K
            return OpcModifColor(7500.0, 0.0, 0.0, vec3<f32>(0.96, 0.98, 1.04), vec3<f32>(0.95, 0.98, 1.05), 1.0);
        }
        case 3u: { // Cine: diafonía 0,15, saturación −0,1, sombras frías y luces cálidas, curva luminancia encendida
            return OpcModifColor(6500.0, -0.1, 0.15, vec3<f32>(0.92, 0.96, 1.06), vec3<f32>(1.06, 1.0, 0.92), 1.15);
        }
        case 4u: { // Vivo: saturación +0,25, diafonía −0,1
            return OpcModifColor(6500.0, 0.25, -0.1, vec3<f32>(1.0), vec3<f32>(1.0), 1.05);
        }
        default: { // Neutro (por defecto)
            return OpcModifColor(6500.0, 0.0, 0.0, vec3<f32>(1.0), vec3<f32>(1.0), 1.0);
        }
    }
}

// 6. Efectos de cámara: apagados (defecto), sutiles, cine (pendiente)
fn opc_efectos_camara() -> u32 {
    return efectos_camara;
}

// 7. Profundidad de campo: apagada (defecto), suave, fuerte (pendiente)
fn opc_profundidad_campo() -> u32 {
    return profundidad_campo;
}

// 8. Estilo de agua: normal (defecto), clara, turbia, pantano
struct OpcModifAgua {
    absorcion: vec3<f32>,
    claridad: f32,
    turbidez: f32,
    causticas_agudeza: f32,
    color_disperso: vec3<f32>,
}

fn opc_estilo_agua() -> OpcModifAgua {
    let abs_base = vec3<f32>(0.39, 0.108, 0.066); // paridad/07 §1 (transmitancia por bloque)
    let disp_base = 0.035;
    let col_disp_base = vec3<f32>(0.04, 0.22, 0.68);
    switch estilo_agua {
        case 1u: { // Clara: absorción ×0,5, claridad ×1,5
            return OpcModifAgua(abs_base * 0.5, 1.5, disp_base, 1.2, col_disp_base);
        }
        case 2u: { // Turbia: absorción ×1,5, claridad ×0,6, turbidez ×4
            return OpcModifAgua(abs_base * 1.5, 0.6, disp_base * 4.0, 0.8, vec3<f32>(0.12, 0.35, 0.45));
        }
        case 3u: { // Pantano: absorción azul ×2 y verde ×0,7, claridad ×0,4
            return OpcModifAgua(vec3<f32>(abs_base.x, abs_base.y * 0.7, abs_base.z * 2.0), 0.4, disp_base * 3.0, 0.6, vec3<f32>(0.2, 0.35, 0.15));
        }
        default: { // Normal (por defecto)
            return OpcModifAgua(abs_base, 1.0, disp_base, 1.0, col_disp_base);
        }
    }
}

// 9. Luz de bloque: cálida (defecto), neutra, fría, vela
struct OpcModifLuzBloque {
    color: vec3<f32>,
    intensidad: f32,
}

fn opc_estilo_luz_bloque() -> OpcModifLuzBloque {
    switch estilo_luz_bloque {
        case 1u: { // Neutra: algo menos roja
            return OpcModifLuzBloque(vec3<f32>(1.0, 0.78, 0.6), 1.0);
        }
        case 2u: { // Fría: casi blanca, un poco azul
            return OpcModifLuzBloque(vec3<f32>(0.75, 0.85, 1.0), 1.0);
        }
        case 3u: { // Vela: más roja, ×0,8
            return OpcModifLuzBloque(vec3<f32>(1.0, 0.35, 0.15), 0.8);
        }
        default: { // Cálida (por defecto)
            return OpcModifLuzBloque(vec3<f32>(1.0, 0.5, 0.25), 1.0);
        }
    }
}

// 10. Noches: natural (defecto), claras, oscuras, sin fases
struct OpcModifNoches {
    mult_luna: f32,
    mult_purkinje: f32,
    luz_minima_exterior: f32,
    sigue_fases: bool,
}

fn opc_estilo_noches() -> OpcModifNoches {
    switch estilo_noches {
        case 1u: { // Claras: luna ×2, visión nocturna ×0,6
            return OpcModifNoches(2.0, 0.6, 0.002, true);
        }
        case 2u: { // Oscuras: luna ×0,5
            return OpcModifNoches(0.5, 1.0, 0.0, true);
        }
        case 3u: { // Sin fases: la luna no sigue la fase
            return OpcModifNoches(1.0, 1.0, 0.0, false);
        }
        default: { // Natural (por defecto)
            return OpcModifNoches(1.0, 1.0, 0.0, true);
        }
    }
}

// 11. Fractal: original (defecto), suave, bandas, salpicadura
struct OpcModifFractal {
    dibujo: u32,
    mult_saturacion: f32,
    ganancia: f32,
}

fn opc_estilo_fractal() -> OpcModifFractal {
    switch estilo_fractal {
        case 1u: { // Suave
            return OpcModifFractal(1u, 1.0, 1.0);
        }
        case 2u: { // Bandas
            return OpcModifFractal(0u, 1.2, 1.2);
        }
        case 3u: { // Salpicadura
            return OpcModifFractal(1u, 1.3, 1.4);
        }
        default: { // Original (por defecto)
            return OpcModifFractal(0u, 1.0, 1.0);
        }
    }
}

// 12. Aurora: discreta, por defecto, amplia
struct OpcModifAurora {
    mult_intensidad: f32,
    mult_radio: f32,
    mult_largo: f32,
    mult_velo: f32,
    mult_ventana: f32,
}

fn opc_estilo_aurora() -> OpcModifAurora {
    switch estilo_aurora {
        case 0u: { // Discreta: ×0,5, cortina más corta, menos vetas
            return OpcModifAurora(0.5, 0.8, 0.7, 0.8, 0.8);
        }
        case 2u: { // Amplia: radio ×2, cortina ×1,7, ventana ×1,5
            return OpcModifAurora(1.0, 2.0, 1.7, 1.2, 1.5);
        }
        default: { // Por defecto
            return OpcModifAurora(1.0, 1.0, 1.0, 1.0, 1.0);
        }
    }
}

// 13. Rayos: sutiles, normales (defecto), dramáticos
struct OpcModifRayos {
    mult_foco: f32,
    mult_longitud: f32,
    mult_caida: f32,
    mult_umbral: f32,
    mult_limitador: f32,
}

fn opc_estilo_rayos() -> OpcModifRayos {
    switch estilo_rayos {
        case 0u: { // Sutiles: más foco, menos largo, umbral más alto
            return OpcModifRayos(1.3, 0.7, 1.1, 1.5, 0.8);
        }
        case 2u: { // Dramáticos: menos foco, más largo, caída más lenta, limitador más alto
            return OpcModifRayos(0.7, 1.5, 0.7, 0.8, 1.3);
        }
        default: { // Normales (por defecto)
            return OpcModifRayos(1.0, 1.0, 1.0, 1.0, 1.0);
        }
    }
}

// 14. Efectos de juego: apagados, sutiles, por defecto, intensos (pendiente de API de daño/fuego)
fn opc_efectos_juego() -> u32 {
    return efectos_juego;
}

// 15. Atmósfera Nether: despejada (×0,5), estándar (defecto), sofocante (×1,5)
fn opc_estilo_atmosfera_nether() -> f32 {
    switch atmosfera_nether {
        case 0u: { return 0.5; }
        case 2u: { return 1.5; }
        default: { return 1.0; }
    }
}

// 16. Tormenta End: calma (×0,5, sin relámpagos), estándar (defecto), tormenta (×1,5 y bruma ×1,2)
struct OpcModifEnd {
    densidad: f32,
    bruma: f32,
    relampagos: bool,
}

fn opc_estilo_tormenta_end() -> OpcModifEnd {
    switch tormenta_end {
        case 0u: { return OpcModifEnd(0.5, 0.8, false); }
        case 2u: { return OpcModifEnd(1.5, 1.2, true); }
        default: { return OpcModifEnd(1.0, 1.0, true); }
    }
}

// 17. Cuevas: abiertas, por defecto, oscuras, muy oscuras
struct OpcModifCuevas {
    niebla_cueva: bool,
    caida: f32,
    mult_luz_minima: f32,
    oscurecer_cielo: bool,
}

fn opc_estilo_cuevas() -> OpcModifCuevas {
    switch estilo_cuevas {
        case 0u: { // Abiertas: sin niebla de cueva, luz mínima ×1,3
            return OpcModifCuevas(false, 1.0, 1.3, false);
        }
        case 2u: { // Oscuras: oscurecer el cielo, caída ×2, luz mínima ×0,33
            return OpcModifCuevas(true, 2.0, 0.33, true);
        }
        case 3u: { // Muy oscuras: luz mínima 0
            return OpcModifCuevas(true, 2.5, 0.0, true);
        }
        default: { // Por defecto
            return OpcModifCuevas(true, 1.0, 1.0, false);
        }
    }
}
