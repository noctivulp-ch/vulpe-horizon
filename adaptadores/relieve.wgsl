// Adaptador de la etapa [displacement] de Horizon (subsistema 18).
// Porqué: docs/efectos/relieve.md §Adaptador

fn adp_desplazamiento(input: DisplacementInput) -> f32 {
    let o = opc_relieve();
    if !o.activa {
        return 0.0;
    }
    let dist = length(input.position);
    let params = SupParametrosRelieve(
        o.profundidad,
        o.distancia,
        o.celdas,
        o.escalonado,
    );
    return sup_relieve_profundidad(input.height, dist, input.material, params);
}
