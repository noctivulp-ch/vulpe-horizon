// Ajustes del cielo fractal. Porqué: docs/efectos/cielo-fractal.md §Opciones
override fractal_brillo: i32 = 40;          // brillo del fractal (0..200, 0 = apagado) (§1)
override fractal_cobertura: i32 = 45;       // cobertura del cielo (5..80 %) (§1)
override fractal_paleta: u32 = 5u;          // paleta (0..5, por defecto cielo invertido) (§1)
override fractal_cambia_cada_noche: bool = true; // otro fractal cada noche (§1)

// Opciones que pasaron a constantes con nombre resueltas por presets o mod nativo (§2.2 y §3)
const OPC_FRACTAL_CONJUNTOS_DEFECTO: i32 = 6;
const OPC_FRACTAL_SEMILLA_DEFECTO: i32 = 8;
const OPC_FRACTAL_SORTEO_DEFECTO: u32 = 0u;          // como el original
const OPC_FRACTAL_SATURACION_DEFECTO: f32 = 70.0;    // %
const FRACTAL_TECHO: f32 = 150.0;
const FRACTAL_CONTRASTE: f32 = 60.0;
const FRACTAL_MUTACION: f32 = 25.0;                  // %
const FRACTAL_HUECO: f32 = 40.0;

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

    let mod_fractal = opc_estilo_fractal();

    return OpcFractal(
        fractal_brillo > 0, fractal_cambia_cada_noche, f32(fractal_cobertura), OPC_FRACTAL_CONJUNTOS_DEFECTO,
        OPC_FRACTAL_SEMILLA_DEFECTO, fractal_paleta,
        f32(fractal_brillo) * OPC_FRACTAL_ESCALA * mod_fractal.ganancia, FRACTAL_TECHO * OPC_FRACTAL_ESCALA * 4.0,
        OPC_FRACTAL_SATURACION_DEFECTO * 0.01 * mod_fractal.mult_saturacion, FRACTAL_CONTRASTE * 0.01,
        FRACTAL_MUTACION * 0.01, FRACTAL_HUECO, mod_fractal.dibujo,
        OPC_FRACTAL_SORTEO_DEFECTO == 0u, iteraciones,
    );
}
