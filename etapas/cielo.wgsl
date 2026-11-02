// Etapa sky: compone la atmósfera, las estrellas y el disco del sol (subsistema 01) y el cielo fractal (02).
// Porqué: docs/efectos/cielo-y-atmosfera.md y docs/efectos/cielo-fractal.md
fn sky(input: SkyInput) -> vec4<f32> {
    let rayo = adp_cielo_rayo(input);
    let dir = rayo.direccion;
    let ajustes = opc_cielo();
    let sol = adp_luz_sol(ajustes);
    let luna = adp_luz_luna(ajustes);

    // Bajo el horizonte la atmósfera se evalúa mirando al horizonte: en Minecraft el terreno acaba antes que
    // el horizonte del planeta y lo que se ve detrás tiene que fundirse con la bruma, no con el suelo del
    // planeta (que dejaba una banda oscura). Porqué: docs/efectos/cielo-y-atmosfera.md §Montaje
    // Solo hasta el ángulo en que se ve el final de la distancia de renderizado (crece con la altura de la
    // cámara): más abajo ya es suelo.
    let borde = adp_cielo_borde_del_mundo();
    let dir_atm = normalize(vec3<f32>(dir.x, max(dir.y, 0.0), dir.z));
    let atm = adp_dispersion(dir_atm, sol, luna, ajustes);

    // Fondo: lo que está más allá de la atmósfera, atenuado por ella.
    var fondo = vec3<f32>(0.0);
    let noche = adp_factor_noche();
    var estrellas = 0.0;
    if ajustes.estrellas_activas && noche > 0.0 {
        estrellas = cie_estrellas(dir, ajustes.estrellas);
        fondo += vec3<f32>(estrellas * noche);
    }
    let fractal = opc_fractal();
    if fractal.activo && noche > 0.0 {
        let mascara = estrellas / max(ajustes.estrellas.brillo, 1e-9);
        let escena = CieFractalEscena(dir, frame.sun_direction, noche, mascara);
        fondo += cie_fractal(escena, adp_fractal_ajustes(fractal, adp_cielo_medio(ajustes)));
    }
    let disco = atm_disco(dot(dir, sol.direccion), OPC_SOL_DISCO_RADIO, 0.15) * (1.0 - frame.rain);
    fondo += sol.irradiancia * OPC_SOL_DISCO_BRILLO * disco;

    // Bajo el horizonte la bruma sigue entera unos grados y el «suelo» llega despacio: si no, el terreno que
    // acaba antes del horizonte (el mar lejano) quedaba contra una franja gris.
    let suelo = cie_factor_suelo(dir.y + borde, 0.08);
    var cielo = atm.luz * mix(0.8, 1.0, suelo) + fondo * atm.transmitancia * cie_factor_suelo(dir.y, 0.03);
    cielo = mix(cie_color_bajo_horizonte(adp_cielo_medio(ajustes), adp_suelo(ajustes), 0.35), cielo, suelo);
    cielo = col_saturar(cielo, OPC_CIELO_SATURACION) * OPC_CIELO_BRILLO_DIBUJO;
    cielo = cie_aplicar_lluvia(cielo, dir.y, adp_lluvia(ajustes));
    return adp_cielo_salida(cielo, dir);
}
