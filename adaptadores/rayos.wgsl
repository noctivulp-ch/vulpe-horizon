// Los rayos del fractal en la pasada final: el centro de la instancia 0 de la noche proyectado a pantalla, la fase
// de la niebla y el factor de noche. Porqué: docs/efectos/rayos-del-fractal.md §Adaptadores
fn adp_rayos(uv: vec2<f32>, pixel: vec2<f32>, exposicion: f32) -> vec3<f32> {
    let noche = adp_factor_noche();
    let o_rayos = opc_rayos();
    if !o_rayos.activo || noche <= 0.0 || !opc_fractal().activo {
        return vec3<f32>(0.0);
    }
    let sorteo = adp_fractal_sorteo(opc_fractal());
    let s = cie_fractal_semilla(sorteo);
    let inst = cie_fractal_instancia(0, s, cie_fractal_cuantos(s, sorteo), sorteo);
    // El eje de la instancia: la matriz de colocación lleva el cenit a él.
    let centro = inst.colocacion * vec3<f32>(0.0, 1.0, 0.0);
    let sobre = smoothstep(-0.12, 0.06, centro.y);
    let en_vista = (frame.view * vec4<f32>(centro, 0.0)).xyz;
    let convergente = en_vista.z > 0.0;
    let polo = select(centro, -centro, convergente);
    var pv = (frame.view * vec4<f32>(polo, 0.0)).xyz;
    // Cerca de 90°, el polo casi en el plano de la cámara: se empuja hacia delante (guard band) y se desvanece.
    let peso_polo = smoothstep(0.02, 0.2, -pv.z / length(pv));
    pv.z = min(pv.z, -0.05);
    let clip = frame.projection * vec4<f32>(pv, 1.0);
    let origen = mat_ndc_a_uv(clip.xy / clip.w);
    let j = select(0, 1, convergente);
    let r = ImgRayos(origen, convergente, o_rayos.intensidad * 0.01 * select(1.0, OPC_RAYOS_ESPALDAS * 0.01, convergente),
                     OPC_RAYOS_FOCO[j] * 0.01, OPC_RAYOS_LONGITUD[j] * 0.01, OPC_RAYOS_CAIDA * 0.01, OPC_RAYOS_UMBRAL[j] * 0.01,
                     OPC_RAYOS_NUCLEO[j] * 0.001, o_rayos.muestras, OPC_RAYOS_OCLUSION * 0.01, exposicion,
                     adp_ruido_azul(pixel, 0u));
    // Fase de la niebla (05), normalizada a su valor de frente, más un término múltiple con lóbulo trasero.
    let dir = normalize(view_position(uv, 1e-4));
    let c = dot(dir, centro);
    let fase = vol_fase_niebla(c) / vol_fase_niebla(1.0) + 0.15 * vol_hg(c, -0.3) / vol_hg(-1.0, -0.3) * OPC_RAYOS_ATRAS * 0.01;
    return img_rayos(uv, previous, linear_sampler, r) * fase * sobre * peso_polo * noche;
}
