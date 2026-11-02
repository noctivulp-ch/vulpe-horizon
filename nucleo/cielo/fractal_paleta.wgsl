// Paletas del cielo fractal y techo de brillo. PROPIO de Vulpe (especificación 02 §4).
// Porqué: docs/efectos/cielo-fractal.md §Color

const CIE_PALETA_AURORA: u32 = 0u;
const CIE_PALETA_BRASA: u32 = 1u;
const CIE_PALETA_HIELO: u32 = 2u;
const CIE_PALETA_MONOCROMO: u32 = 3u;
const CIE_PALETA_CIELO: u32 = 4u;
const CIE_PALETA_CIELO_INVERTIDO: u32 = 5u;

struct CiePaleta {
    estilo: u32,
    contraste: f32,     // exponente sobre t (0,6 por defecto)
    saturacion: f32,    // 0..1: mezcla con blanco
    cielo: vec3<f32>,   // color medio del cielo de esta noche (para las paletas del cielo)
}

// Paleta cosenoidal (Í. Quílez, «Palettes»): a + b·cos(2π(c·t + d)).
fn cie_coseno(t: f32, a: vec3<f32>, b: vec3<f32>, c: vec3<f32>, d: vec3<f32>) -> vec3<f32> {
    return max(a + b * cos(MAT_TAU * (c * t + d)), vec3<f32>(0.0));
}

fn cie_paleta(t_entrada: f32, desfase: f32, p: CiePaleta) -> vec3<f32> {
    var t = pow(clamp(t_entrada, 0.0, 1.0), p.contraste);
    t = fract(t + desfase);
    switch p.estilo {
        case CIE_PALETA_MONOCROMO: { return vec3<f32>(t); }
        case CIE_PALETA_CIELO, CIE_PALETA_CIELO_INVERTIDO: {
            var tono = p.cielo / max(max(p.cielo.r, max(p.cielo.g, p.cielo.b)), 1e-4);
            if p.estilo == CIE_PALETA_CIELO_INVERTIDO {
                tono = clamp(vec3<f32>(1.0) - tono, vec3<f32>(0.0), vec3<f32>(1.0));
            }
            return mix(vec3<f32>(t), tono * (0.35 + 0.65 * t), 0.85);
        }
        case CIE_PALETA_BRASA: {
            return cie_coseno(t, vec3<f32>(0.35, 0.16, 0.09), vec3<f32>(0.45, 0.25, 0.12), vec3<f32>(1.0, 1.0, 0.6), vec3<f32>(0.0, 0.12, 0.2));
        }
        case CIE_PALETA_HIELO: {
            return cie_coseno(t, vec3<f32>(0.22, 0.30, 0.45), vec3<f32>(0.28, 0.32, 0.45), vec3<f32>(1.0), vec3<f32>(0.55, 0.62, 0.72));
        }
        default: {
            return cie_coseno(t, vec3<f32>(0.32, 0.26, 0.38), vec3<f32>(0.38, 0.34, 0.42), vec3<f32>(1.0, 1.0, 0.85), vec3<f32>(0.0, 0.33, 0.67));
        }
    }
}

// Solo el tono: normalizado a su canal máximo y mezclado con blanco según la saturación.
fn cie_tono(color: vec3<f32>, saturacion: f32) -> vec3<f32> {
    let tono = color / max(max(color.r, max(color.g, color.b)), 1e-4);
    return mix(vec3<f32>(1.0), tono, saturacion);
}

// Reinhard sobre el canal máximo: acota el pico conservando el tono.
fn cie_techo(color: vec3<f32>, techo: f32) -> vec3<f32> {
    if techo <= 0.0 {
        return color;
    }
    return color / (1.0 + max(color.r, max(color.g, color.b)) / techo);
}
