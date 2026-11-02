// Ajustes del cielo fractal. Porqué: docs/efectos/cielo-fractal.md §Opciones
override fractal: bool = true;
override fractal_cambios_noche: bool = true;
override fractal_cobertura: f32 = 45.0;     // %
override fractal_conjuntos: i32 = 6;
override fractal_semilla: i32 = 8;
override fractal_paleta: u32 = 5u;          // cielo invertido
override fractal_brillo: f32 = 40.0;
override fractal_techo: f32 = 150.0;
override fractal_saturacion: f32 = 70.0;    // %
override fractal_contraste: f32 = 60.0;
override fractal_mutacion: f32 = 25.0;      // %
override fractal_hueco: f32 = 40.0;
override fractal_dibujo: u32 = 0u;          // original

// Escala de brillo y techo en la escala común: el fractal queda del orden de las estrellas tenues.
const OPC_FRACTAL_ESCALA: f32 = 0.8e-5;
const OPC_FRACTAL_ITERACIONES: i32 = 100;

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
}

fn opc_fractal() -> OpcFractal {
    return OpcFractal(
        fractal, fractal_cambios_noche, fractal_cobertura, fractal_conjuntos, fractal_semilla, fractal_paleta,
        fractal_brillo * OPC_FRACTAL_ESCALA, fractal_techo * OPC_FRACTAL_ESCALA * 4.0,
        fractal_saturacion * 0.01, fractal_contraste * 0.01, fractal_mutacion * 0.01, fractal_hueco, fractal_dibujo,
    );
}
