// Decodificación del estándar LabPBR (shaderlabs.org/wiki/LabPBR_Material_Standard).
// Porqué: docs/efectos/luz-de-superficie.md §LabPBR

struct SupMaterial {
    suavidad: f32,          // perceptual, 0..1
    rugosidad: f32,         // lineal = (1 − suavidad)²
    f0: vec3<f32>,
    metal: bool,
    sss: f32,               // 0..1 (canal azul por encima de 65/255)
    porosidad: f32,         // 0..1 (canal azul por debajo de 65/255)
    emision: f32,           // 0..1 (alfa por debajo de 255)
}

// F0 de un conductor desde sus índices complejos n y k (incidencia normal).
fn sup_f0_conductor(n: vec3<f32>, k: vec3<f32>) -> vec3<f32> {
    let uno = vec3<f32>(1.0);
    return ((uno - n) * (uno - n) + k * k) / ((uno + n) * (uno + n) + k * k);
}

// Metales predefinidos de LabPBR, 230..237: hierro, oro, aluminio, cromo, cobre, plomo, platino, plata.
// n y k (R, G, B) de la tabla del propio estándar.
fn sup_metal_predefinido(i: u32) -> vec3<f32> {
    switch i {
        case 0u: { return sup_f0_conductor(vec3<f32>(2.9114, 2.9497, 2.5845), vec3<f32>(3.0893, 2.9318, 2.7670)); }
        case 1u: { return sup_f0_conductor(vec3<f32>(0.18299, 0.42108, 1.3734), vec3<f32>(3.4242, 2.3459, 1.7704)); }
        case 2u: { return sup_f0_conductor(vec3<f32>(1.3456, 0.96521, 0.61722), vec3<f32>(7.4746, 6.3995, 5.3031)); }
        case 3u: { return sup_f0_conductor(vec3<f32>(3.1071, 3.1812, 2.3230), vec3<f32>(3.3314, 3.3291, 3.1350)); }
        case 4u: { return sup_f0_conductor(vec3<f32>(0.27105, 0.67693, 1.31640), vec3<f32>(3.6092, 2.6248, 2.2921)); }
        case 5u: { return sup_f0_conductor(vec3<f32>(1.9100, 1.8300, 1.4400), vec3<f32>(3.5100, 3.4000, 3.1800)); }
        case 6u: { return sup_f0_conductor(vec3<f32>(2.3757, 2.0847, 1.8453), vec3<f32>(4.2655, 3.7153, 3.1365)); }
        default: { return sup_f0_conductor(vec3<f32>(0.15943, 0.14512, 0.13547), vec3<f32>(3.9291, 3.1900, 2.3808)); }
    }
}

// `especular`: el mapa _s tal cual (0..1); `albedo` lineal.
fn sup_labpbr(especular: vec4<f32>, albedo: vec3<f32>) -> SupMaterial {
    var m: SupMaterial;
    m.suavidad = especular.r;
    m.rugosidad = (1.0 - m.suavidad) * (1.0 - m.suavidad);
    let g = u32(round(especular.g * 255.0));
    m.metal = g >= 230u;
    if g < 230u {
        m.f0 = vec3<f32>(especular.g);
    } else if g <= 237u {
        m.f0 = sup_metal_predefinido(g - 230u);
    } else {
        m.f0 = albedo;
    }
    let b = especular.b * 255.0;
    m.sss = select(0.0, (b - 65.0) / 190.0, b > 65.0);
    m.porosidad = select(b / 64.0, 0.0, b > 65.0);
    let a = u32(round(especular.a * 255.0));
    m.emision = select(especular.a * 255.0 / 254.0, 0.0, a >= 255u);
    return m;
}

// Normal del mapa _n (rg en [0, 1], z reconstruida) llevada a ejes del mundo con la base de la cara.
fn sup_normal_mapa(mapa: vec4<f32>, n: vec3<f32>, tangente: vec4<f32>) -> vec3<f32> {
    let xy = mapa.rg * 2.0 - 1.0;
    let z = sqrt(max(1.0 - dot(xy, xy), 0.0));
    let t = tangente.xyz;
    let b = cross(n, t) * tangente.w;
    return normalize(t * xy.x + b * xy.y + n * z);
}
