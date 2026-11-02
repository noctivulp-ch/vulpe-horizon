// BRDF de microfacetas GGX con Smith correlacionado y Fresnel de Schlick. Porqué: docs/efectos/luz-de-superficie.md §Especular

// Distribución GGX / Trowbridge-Reitz (Walter et al. 2007), `a` = α = rugosidad lineal = (1 − suavidad)².
fn sup_ggx(n_h: f32, a: f32) -> f32 {
    let a2 = a * a;
    let d = n_h * n_h * (a2 - 1.0) + 1.0;
    return a2 / (MAT_PI * d * d + 1e-7);
}

// Visibilidad de Smith-GGX correlacionada en altura (Heitz 2014), ya dividida por 4·N·V·N·L.
fn sup_visibilidad_smith(n_v: f32, n_l: f32, a: f32) -> f32 {
    let a2 = a * a;
    let gv = n_l * sqrt(n_v * n_v * (1.0 - a2) + a2);
    let gl = n_v * sqrt(n_l * n_l * (1.0 - a2) + a2);
    return 0.5 / max(gv + gl, 1e-5);
}

fn sup_fresnel_schlick(cos_theta: f32, f0: vec3<f32>) -> vec3<f32> {
    let k = pow(1.0 - clamp(cos_theta, 0.0, 1.0), 5.0);
    return f0 + (vec3<f32>(1.0) - f0) * k;
}

// Schlick con rugosidad (Lagarde y de Rousiers 2014): el reflejo del ambiente de una superficie rugosa no
// llega a blanco en ángulo rasante.
fn sup_fresnel_schlick_rugosidad(cos_theta: f32, f0: vec3<f32>, rugosidad: f32) -> vec3<f32> {
    let k = pow(1.0 - clamp(cos_theta, 0.0, 1.0), 5.0);
    return f0 + (max(vec3<f32>(1.0 - rugosidad), f0) - f0) * k;
}

// BRDF especular f_s(l, v) en sr⁻¹ (sin el N·L). `rugosidad` es la lineal (α): no se vuelve a elevar al
// cuadrado. Porqué: docs/efectos/luz-de-superficie.md §Especular
fn sup_especular(n: vec3<f32>, v: vec3<f32>, l: vec3<f32>, rugosidad: f32, f0: vec3<f32>) -> vec3<f32> {
    let h = normalize(v + l);
    let n_v = max(dot(n, v), 1e-4);
    let n_l = max(dot(n, l), 0.0);
    let n_h = max(dot(n, h), 0.0);
    let a = max(rugosidad, 0.002);
    return sup_ggx(n_h, a) * sup_visibilidad_smith(n_v, n_l, a) * sup_fresnel_schlick(dot(v, h), f0);
}

// Normal de microfaceta muestreada de la distribución de normales visibles de GGX (Heitz, «Sampling the GGX
// Distribution of Visible Normals», JCGT 2018), en el espacio local de la superficie (z = normal). `v` hacia
// el observador, `a` = α (la rugosidad lineal), `u` dos números en [0, 1).
fn sup_muestrear_vndf(v: vec3<f32>, a: f32, u: vec2<f32>) -> vec3<f32> {
    let vh = normalize(vec3<f32>(a * v.x, a * v.y, v.z));
    let l2 = vh.x * vh.x + vh.y * vh.y;
    let t1 = select(vec3<f32>(1.0, 0.0, 0.0), vec3<f32>(-vh.y, vh.x, 0.0) / sqrt(l2), l2 > 0.0);
    let t2 = cross(vh, t1);
    let r = sqrt(u.x);
    let fi = MAT_TAU * u.y;
    let p1 = r * cos(fi);
    var p2 = r * sin(fi);
    let s = 0.5 * (1.0 + vh.z);
    p2 = (1.0 - s) * sqrt(1.0 - p1 * p1) + s * p2;
    let nh = p1 * t1 + p2 * t2 + sqrt(max(0.0, 1.0 - p1 * p1 - p2 * p2)) * vh;
    return normalize(vec3<f32>(a * nh.x, a * nh.y, max(0.0, nh.z)));
}

// Base ortonormal (t, b, n) alrededor de `n` (Duff et al., «Building an Orthonormal Basis, Revisited», JCGT 2017).
fn sup_base(n: vec3<f32>) -> mat3x3<f32> {
    let signo = select(-1.0, 1.0, n.z >= 0.0);
    let a = -1.0 / (signo + n.z);
    let b = n.x * n.y * a;
    let t = vec3<f32>(1.0 + signo * n.x * n.x * a, signo * b, -signo * n.x);
    let bt = vec3<f32>(b, signo + n.y * n.y * a, -n.y);
    return mat3x3<f32>(t, bt, n);
}
