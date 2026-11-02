// Ajustes de la imagen final (exposición, tonos, gradación). Porqué: docs/efectos/nucleo.md §Color
override imagen_exposicion: f32 = 0.0;
override imagen_saturacion: f32 = 1.0;
override imagen_contraste: f32 = 1.0;
override imagen_tonemap: u32 = 0u;
override imagen_tramado: bool = true;

struct OpcImagen {
    gradacion: ColParametrosGradacion,
    tonemap: u32,
    tramado: bool,
}

fn opc_imagen() -> OpcImagen {
    return OpcImagen(
        ColParametrosGradacion(imagen_exposicion, imagen_saturacion, imagen_contraste),
        imagen_tonemap,
        imagen_tramado,
    );
}
