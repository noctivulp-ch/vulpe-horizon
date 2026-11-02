// Etapa sky: compone la atmósfera, las estrellas y el disco del sol (subsistema 01).
// Porqué: docs/efectos/cielo-y-atmosfera.md
fn sky(input: SkyInput) -> vec4<f32> {
    let rayo = adp_cielo_rayo(input);
    let dir = rayo.direccion;
    let ajustes = opc_cielo();
    let sol = adp_luz_sol(ajustes);
    let luna = adp_luz_luna(ajustes);

    let atm = adp_dispersion(dir, sol, luna, ajustes);

    // Fondo: lo que está más allá de la atmósfera, atenuado por ella.
    var fondo = vec3<f32>(0.0);
    let noche = adp_factor_noche();
    if ajustes.estrellas_activas && noche > 0.0 {
        fondo += vec3<f32>(cie_estrellas(dir, ajustes.estrellas) * noche);
    }
    let disco = atm_disco(dot(dir, sol.direccion), OPC_SOL_DISCO_RADIO, 0.15) * (1.0 - frame.rain);
    fondo += sol.irradiancia * OPC_SOL_DISCO_BRILLO * disco;

    let suelo = cie_factor_suelo(dir.y, 0.06);
    var cielo = atm.luz * mix(0.6, 1.0, suelo) + fondo * atm.transmitancia * suelo;
    cielo = mix(cie_color_bajo_horizonte(adp_cielo_medio(ajustes), adp_suelo(ajustes), 0.35), cielo, suelo);
    cielo = col_saturar(cielo, OPC_CIELO_SATURACION);
    cielo = cie_aplicar_lluvia(cielo, dir.y, adp_lluvia(ajustes));
    return adp_cielo_salida(cielo, dir);
}
