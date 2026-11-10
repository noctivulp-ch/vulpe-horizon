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
        let escena = CieFractalEscena(adp_cielo_jitter(dir), frame.sun_direction, noche, mascara);
        fondo += cie_fractal(escena, adp_fractal_ajustes(fractal, adp_cielo_medio(ajustes)));
    }
    // Bajo el horizonte: bruma cerca de él y suelo al mirar más abajo, con la misma regla de ángulo que la
    // niebla de borde (05). Así el terreno que acaba antes del horizonte se funde con lo que hay detrás a
    // cualquier altura de la cámara.
    let suelo = cie_peso_bruma_horizonte(dir.y);
    var cielo = atm.luz * mix(0.8, 1.0, suelo) + fondo * atm.transmitancia * cie_factor_suelo(dir.y, 0.03);
    cielo = mix(cie_color_bajo_horizonte(adp_cielo_medio(ajustes), adp_suelo(ajustes), 0.35), cielo, suelo);
    cielo = col_saturar(cielo, OPC_CIELO_SATURACION) * OPC_CIELO_BRILLO_DIBUJO;

    // Disco del sol: luz directa ya atenuada y con rampa de horizonte (fino/01 §8),
    // sumado directamente sin multiplicar por la transmitancia del rayo de vista ni por el brillo del dibujo.
    let elev_sol = degrees(asin(clamp(frame.sun_direction.y, -1.0, 1.0)));
    let directa_sol = atm_luz_directa_sol(elev_sol) * ajustes.sol_color;
    let disco = atm_disco(dot(dir, sol.direccion), OPC_SOL_DISCO_RADIO, OPC_SOL_DISCO_BORDE) * (1.0 - frame.rain);
    cielo += directa_sol * OPC_SOL_DISCO_BRILLO * disco * cie_factor_suelo(dir.y, 0.03);

    cielo = cie_aplicar_lluvia(cielo, dir.y, atm.transmitancia, frame.camera_position.y, adp_lluvia(ajustes));
    return adp_cielo_salida(cielo, dir);
}
