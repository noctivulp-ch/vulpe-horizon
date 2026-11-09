// Relieve geométrico teselado con [displacement] (subsistema 18).
// Porqué: docs/efectos/relieve.md §Núcleo

struct SupParametrosRelieve {
    profundidad_max: f32,
    distancia_max: f32,
    celdas: u32,
    escalonado: bool,
}

fn sup_relieve_admite_material(material: u32) -> bool {
    return material != 1u && material != 2u && material != 4u && material != 8u;
}

fn sup_relieve_atenuacion_distancia(distancia: f32, distancia_max: f32) -> f32 {
    let factor = clamp((1.0 - distancia / distancia_max) * 2.0, 0.0, 1.0);
    return factor * factor;
}

fn sup_relieve_profundidad(
    altura: f32,
    distancia: f32,
    material: u32,
    params: SupParametrosRelieve,
) -> f32 {
    if !sup_relieve_admite_material(material) || params.profundidad_max <= 0.0 {
        return 0.0;
    }
    var h = clamp(altura, 0.0, 1.0);
    if h >= 0.999 {
        return 0.0;
    }
    if params.escalonado && params.celdas > 0u {
        let n = f32(params.celdas);
        h = floor(h * n) / n;
    }
    let aten = sup_relieve_atenuacion_distancia(distancia, params.distancia_max);
    return (1.0 - h) * params.profundidad_max * aten;
}
