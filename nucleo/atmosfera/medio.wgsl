// Densidades y coeficientes del medio a una altura. Porqué: docs/efectos/cielo-y-atmosfera.md §Modelo

struct AtmMedio {
    rayleigh: vec3<f32>,    // dispersión de Rayleigh, m⁻¹
    mie: f32,               // dispersión de Mie, m⁻¹
    extincion: vec3<f32>,   // dispersión + absorción total, m⁻¹
}

// `altura` sobre el suelo del planeta, m. `bruma` multiplica los aerosoles.
fn atm_medio(altura: f32, p: AtmParametros, bruma: f32) -> AtmMedio {
    let h = max(altura, 0.0);
    let d_r = exp(-h / p.rayleigh_altura);
    let d_m = exp(-h / p.mie_altura) * bruma;
    let d_o = max(0.0, 1.0 - abs(h - p.ozono_centro) / p.ozono_semiancho);
    let r = p.rayleigh_dispersion * d_r;
    let m = p.mie_dispersion * d_m;
    let ext = r + vec3<f32>(m + p.mie_absorcion * d_m) + p.ozono_absorcion * d_o;
    return AtmMedio(r, m, ext);
}
