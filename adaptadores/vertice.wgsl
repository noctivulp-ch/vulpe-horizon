// VertexInput → la familia de la planta, la fase en el mundo y la amplitud por el viento, la lluvia y la luz de
// cielo. Porqué: docs/efectos/vegetacion-ondulante.md §Adaptadores
fn adp_vertice_ondulado(input: VertexInput) -> vec3<f32> {
    if ondulacion <= 0 || input.fluid != 0u {
        return input.position;
    }
    let m = input.material;
    let hojas = m == OPC_MAT_HOJAS;
    let alta_arriba = m == OPC_MAT_PLANTA_ALTA_ARRIBA;
    let colgantes = m == OPC_MAT_COLGANTES;
    let suelo = m == OPC_MAT_PLANTA_FUERTE || m == OPC_MAT_PLANTA_MEDIA;
    if !(hojas || alta_arriba || suelo || colgantes) {
        return input.position;
    }
    // Solo bajo el cielo y cerca (formas/vegetacion.md §1): bajo techo, en cuevas y a más de 64 bloques, quieto.
    if input.light.y <= OPC_VIENTO_CIELO_MIN || length(input.position) > OPC_VIENTO_ALCANCE {
        return input.position;
    }
    // Plantas de suelo: solo la mitad de arriba del sprite (la base queda clavada); colgantes: solo la de abajo (arriba
    // quedan clavadas). uv.y en el espacio del sprite, 0 arriba.
    let uv_y = fract(input.uv.y);
    if (suelo && uv_y > 0.5) || (colgantes && uv_y < 0.5) {
        return input.position;
    }
    let mundo = input.position + frame.camera_position;
    let cielo = select(max(input.light.y, 0.5), input.light.y, hojas || colgantes);
    let v = SupViento(frame.time * (OPC_VIENTO_VELOCIDAD * ondulacion_velocidad), (f32(ondulacion) * 0.02) * (1.0 + frame.rain) * cielo,
                      OPC_VIENTO_PLANTA_PERIODO, OPC_VIENTO_PLANTA_AMPLITUD, OPC_VIENTO_HOJA_PERIODO,
                      OPC_VIENTO_HOJA_AMPLITUD, OPC_VIENTO_HOJA_VERTICAL);
    // Hojas y colgantes (15.1): se mueven todos los vértices en 3D con sup_viento_hoja (15 §Familias).
    // La base de la mitad superior y la punta de la inferior están en la misma posición del mundo: la misma función
    // les da el mismo desplazamiento y no se separan.
    let d = select(sup_viento_planta(floor(mundo + 0.001), v), sup_viento_hoja(mundo, v), hojas || colgantes);
    return input.position + d;
}
