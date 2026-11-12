// Pasada 3: decodifica la escena (ADR 0004), aplica la oclusión ambiental (08), añade los reflejos de pantalla (03) y compone la niebla de
// borde y el volumen (05). Sale luz lineal. Porqué: docs/efectos/niebla-y-nubes.md §Composición y
// docs/efectos/luz-de-superficie.md §Reflejos de pantalla
fn post(input: PostInput) -> vec4<f32> {
    let p = adp_post_pixel(input);
    var c = adp_post_escena(p);
    if opc_depuracion().vista == OPC_VISTA_RELIEVE {
        return vec4<f32>(c, 1.0);
    }
    if opc_vista_forma(opc_depuracion().vista) {
        return vec4<f32>(adp_vista_forma(p.uv, opc_depuracion().vista), 1.0);
    }
    c = adp_aplicar_oclusion(c, p);
    let dir = adp_post_direccion(p);
    let o = opc_luz();
    c += adp_post_reflejo(p, dir, o.pasos_reflejo, o.suavidad_reflejo);
    let borde = adp_post_borde(p, dir);
    c = mix(c, borde.rgb, borde.a);
    // Orden de 23: borde, cueva, volumen, inmersión.
    c = adp_niebla_cueva(c, p, dir);
    let v = adp_volumen_reescalado(p.pixel, adp_post_distancia(p));
    c = c * adp_transmitancia_compuesta(v, adp_post_distancia(p), p.uv) + v.luz;
    c = adp_niebla_inmersion(c, adp_post_distancia(p));
    return vec4<f32>(c, adp_opacidad_bloom_niebla(v, p));
}
