// Ajustes del cielo fractal. Porqué: docs/efectos/cielo-fractal.md §Opciones
override fractal: bool = true;
override fractal_cambios_noche: bool = true;
override fractal_cobertura: f32 = 45.0;     // %
override fractal_conjuntos: i32 = 6;
override fractal_semilla: i32 = 8;
override fractal_sorteo: u32 = 0u;          // como el original, estable
override fractal_paleta: u32 = 5u;          // cielo invertido
override fractal_brillo: f32 = 40.0;
const FRACTAL_TECHO: f32 = 150.0;
override fractal_saturacion: f32 = 70.0;    // %
const FRACTAL_CONTRASTE: f32 = 60.0;
const FRACTAL_MUTACION: f32 = 25.0;      // %
const FRACTAL_HUECO: f32 = 40.0;
const FRACTAL_DIBUJO: u32 = 0u;          // original

// Escala de brillo y techo en la escala común: el fractal queda del orden de las estrellas tenues.
const OPC_FRACTAL_ESCALA: f32 = 0.8e-5;

struct OpcFractal {
    activo: bool,
    cambios_por_noche: bool,
    cobertura: f32,
    conjuntos: i32,
    semilla: i32,
    paleta: u32,
    brillo: f32,
    techo: f32,
    saturacion: f32,
    contraste: f32,
    mutacion: f32,
    hueco: f32,
    dibujo: u32,
    sorteo_original: bool,
    iteraciones: i32,
}

fn opc_fractal() -> OpcFractal {
    let nivel = opc_calidad_fractal();
    var iteraciones = 100;
    switch nivel {
        case 0u: { // Baja: 60 iteraciones
            iteraciones = 60;
        }
        case 1u: { // Media: 100 iteraciones
            iteraciones = 100;
        }
        case 2u: { // Alta: 200 iteraciones
            iteraciones = 200;
        }
        default: { // Ultra: 300 iteraciones
            iteraciones = 300;
        }
    }

    return OpcFractal(
        fractal, fractal_cambios_noche, fractal_cobertura, fractal_conjuntos, fractal_semilla, fractal_paleta,
        fractal_brillo * OPC_FRACTAL_ESCALA, FRACTAL_TECHO * OPC_FRACTAL_ESCALA * 4.0,
        fractal_saturacion * 0.01, FRACTAL_CONTRASTE * 0.01, FRACTAL_MUTACION * 0.01, FRACTAL_HUECO, FRACTAL_DIBUJO,
        fractal_sorteo == 0u, iteraciones,
    );
}
