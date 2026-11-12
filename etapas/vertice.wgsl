// Etapa vertex: compone la vegetación ondulante (subsistema 15), las olas grandes del agua y la curvatura del mundo
// (24), en el mundo y en el mapa de sombras. Porqué: docs/efectos/vegetacion-ondulante.md y docs/efectos/varios.md
fn vertex(input: VertexInput) -> vec3<f32> {
    var p = adp_vertice_ondulado(input);
    if OPC_OLAS_VERTICE > 0.0 && input.fluid == 1u && input.face == 1u {
        p.y += sup_olas_vertice(input.position + frame.camera_position, length(input.position), frame.time, OPC_OLAS_VERTICE);
    }
    if OPC_CURVATURA != 0.0 {
        p.y += sup_curvatura(p, OPC_CURVATURA);
    }
    return p;
}
