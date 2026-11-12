// Los medios del volumen: aire, niebla global y nubes. Porqué: docs/efectos/niebla-y-nubes.md §Medios

struct VolAjustesNiebla {
    uniforme: f32,          // densidad relativa por hora × tiempo
    manchas: f32,
    cantidad: f32,          // multiplicador global (opción)
    bruma: f32,             // multiplicador del aire (opción)
    caida: f32,             // por bloque, por encima de VOL_CAIDA_DESDE
    viento: vec3<f32>,      // desplazamiento de las manchas, bloques
    ambiente: f32,          // multiplicador de la luz ambiente dispersada (>1 en la tormenta de nieve: blanca)
}

// Perspectiva aérea: extinción por bloque medida en paridad/05 §Perspectiva aérea (Y 62..662), con alturas de escala
// distintas para moléculas y aerosoles y un suelo de aerosoles. Porqué: docs/efectos/niebla-y-nubes.md §Perspectiva aérea (F-2)
const VOL_AIRE_RAYLEIGH: vec3<f32> = vec3<f32>(1.45e-4, 3.375e-4, 8.275e-4); // por bloque en VOL_AIRE_Y0
const VOL_AIRE_MIE: f32 = 7.6e-5;                                            // por bloque en VOL_AIRE_Y0, sin el suelo
const VOL_AIRE_MIE_SUELO: f32 = 2.0e-6;                                      // aerosoles que no caen con la altura
const VOL_AIRE_Y0: f32 = 62.0;                                               // cota de referencia de la tabla
const VOL_AIRE_ALTURA_RAYLEIGH: f32 = 1900.0;                                // bloques: altura de escala molecular
const VOL_AIRE_ALTURA_MIE: f32 = 265.0;                                      // bloques: altura de escala de aerosoles
const VOL_NIEBLA_SIGMA: f32 = 0.02;        // por bloque con densidad relativa 1
const VOL_CAIDA_DESDE: f32 = 320.0;         // por encima del velo de la aurora (decisión de Vulpe)
// Manchas de niebla ajustadas a fino/05 «Respuesta a la pregunta 11» (medido a Y = 70 con el parámetro 0,4): mancha en
// el 53 % del volumen, forma media dentro de 0,13 del tope ya con la altura (0,61 a Y = 70), mitad cada 14 bloques por
// encima de Y = 60. Con rampa² sobre el canal A de ruido3d sale 53 % y 0,22 antes de la altura: media 0,0046 por bloque
// (medido 0,004635). Porqué: docs/efectos/niebla-y-nubes.md §«Manchas medidas» (F-19)
const VOL_MANCHAS_RAMPA: vec2<f32> = vec2<f32>(0.46, 0.76);
const VOL_MANCHAS_DESDE: f32 = 60.0;
const VOL_MANCHAS_ALTURA: f32 = 20.2;

struct VolAire {
    rayleigh: vec3<f32>,
    mie: f32,
}

fn vol_aire(y: f32, bruma: f32) -> VolAire {
    let h = max(y - VOL_AIRE_Y0, 0.0);
    let d_r = exp(-h / VOL_AIRE_ALTURA_RAYLEIGH);
    let d_m = exp(-h / VOL_AIRE_ALTURA_MIE);
    return VolAire(VOL_AIRE_RAYLEIGH * (d_r * bruma), (VOL_AIRE_MIE * d_m + VOL_AIRE_MIE_SUELO) * bruma);
}

// Coeficiente de extinción de la niebla global (por bloque) en `mundo`.
// La densidad efectiva es el cubo del parámetro horario/climático (paridad/05 y fino/05 §1, §4).
fn vol_niebla(mundo: vec3<f32>, a: VolAjustesNiebla, ruido3d: texture_2d<f32>) -> f32 {
    var d = a.uniforme * a.uniforme * a.uniforme;
    if a.manchas > 0.0 {
        let p = (mundo + a.viento) * vec3<f32>(1.0 / 96.0, 1.0 / 40.0, 1.0 / 96.0);
        let n = vol_ruido3d(ruido3d, p).a;
        let rampa = smoothstep(VOL_MANCHAS_RAMPA.x, VOL_MANCHAS_RAMPA.y, n);
        let mancha = rampa * rampa * exp(-max(mundo.y - VOL_MANCHAS_DESDE, 0.0) / VOL_MANCHAS_ALTURA);
        let d_manchas = a.manchas * a.manchas * a.manchas;
        d += d_manchas * mancha;
    }
    d *= exp(-max(mundo.y - VOL_CAIDA_DESDE, 0.0) * a.caida);
    return d * a.cantidad;
}

// Huella del píxel (en vóxeles del ruido) entre la que el ruido de erosión pasa de entero a su valor medio.
const VOL_NUBES_LOD: vec2<f32> = vec2<f32>(0.5, 1.5);

// Niebla local de bioma y de clima (21): uniforme + manchas tal cual (sin cubo), con su color propio.
struct VolNieblaLocal {
    uniforme: f32,          // extinción por bloque
    manchas: f32,
    color: vec3<f32>,       // multiplica la luminancia de la luz directa y de la ambiente
    viento: vec3<f32>,      // desplazamiento de las manchas, bloques (con un descenso lento)
}

// Densidad local: la parte uniforme no cae con la altura; las manchas usan un ruido más fino que el global, aplastado
// en vertical, y solo su parte alta (el quinto inferior se recorta). Porqué: docs/efectos/niebla-local.md (F-28)
fn vol_niebla_local(mundo: vec3<f32>, l: VolNieblaLocal, ruido3d: texture_2d<f32>) -> f32 {
    var d = l.uniforme;
    if l.manchas > 0.0 {
        let p = (mundo + l.viento) * vec3<f32>(1.0 / VOL_LOCAL_ESCALA.x, 1.0 / VOL_LOCAL_ESCALA.y, 1.0 / VOL_LOCAL_ESCALA.x);
        let n = vol_ruido3d(ruido3d, p).a;
        d += l.manchas * max(n - 0.2, 0.0) / 0.8;
    }
    return d;
}

// Tamaño de las manchas de la niebla local: horizontal × vertical, bloques (más fino que el global y aplastado; sin medir).
const VOL_LOCAL_ESCALA: vec2<f32> = vec2<f32>(48.0, 12.0);

// `remap(v, bajo, 1)`: lo que queda por encima de `bajo`, reescalado a 0..1.
fn vol_remapear(v: f32, bajo: f32) -> f32 {
    return clamp((v - bajo) / max(1.0 - bajo, 1e-3), 0.0, 1.0);
}

// Densidad 0..1 de la capa de nubes `i` en `mundo`: cobertura 2D × perfil vertical, erosionada en los bordes.
// `erosion`: falso en las muestras de luz hacia el astro (solo cobertura y forma: la especificación lo prevé
// para el presupuesto).
// `huella`: bloques que cubre un píxel del volumen a esa distancia. El ruido de erosión se apaga cuando su vóxel queda por
// debajo de la huella (si no, en las nubes lejanas salía grano que el TAA no promedia).
// Porqué: docs/efectos/niebla-y-nubes.md §«Grano del borde» (F-23)
fn vol_nube(mundo: vec3<f32>, i: i32, n: VolNubes, t2: texture_2d<f32>, s2: sampler, t3: texture_2d<f32>, erosion: bool, huella: f32) -> f32 {
    let dy = mundo.y - (VOL_MAR + VOL_BASE[i]);
    let h = dy / VOL_ESPESOR[i];
    if h <= 0.0 || h >= 1.0 {
        return 0.0;
    }
    let inclinado = mundo.xz + n.direccion * (h * VOL_ESPESOR[i] * n.forma.inclinacion);
    let cob = vol_cobertura(inclinado, i, n, t2, s2);
    if cob <= 0.0 {
        return 0.0;
    }
    if i == 2 {
        return cob * smoothstep(0.0, 0.3, h) * (1.0 - smoothstep(0.7, 1.0, h)) * n.perfil.densidad[i];
    }
    // Perfil vertical (formas/nubes.md §4): resta a la forma lo que le falta para 1, así el borde es además más bajo.
    var d = cob - (1.0 - vol_perfil_cumulo(h, i));
    if d <= 0.0 {
        return 0.0;
    }
    if !erosion {
        // Versión barata (§5): la erosión media.
        return max(d - n.forma.erosion_media, 0.0) * n.perfil.densidad[i];
    }
    // Erosión (§5): ruido 3D grueso, que pesa con la raíz de lo que le falta a la forma, y fino solo en el borde, que se
    // invierte hacia el techo (de comer huecos a dejar jirones); la suma a la cuarta muerde de golpe donde coinciden
    // altos, y se resta la mitad. El detalle resbala sobre la masa (el viento de la erosión es mayor que el de la forma).
    // Porqué: docs/efectos/niebla-y-nubes.md §«Forma de las nubes (F-36)»
    let deriva = n.viento * select(0.74, 1.0, i == 0);
    let q = vec3<f32>(inclinado.x + deriva.x, mundo.y, inclinado.y + deriva.y);
    let eg = select(n.forma.escala_erosion.zw, n.forma.escala_erosion.xy, i == 0);
    let ef = select(n.forma.escala_detalle.zw, n.forma.escala_detalle.xy, i == 0);
    let falta = clamp(1.0 - cob, 0.0, 1.0);
    let lod_gruesa = 1.0 - smoothstep(VOL_NUBES_LOD.x, VOL_NUBES_LOD.y, huella * 32.0 / eg.x);
    let lod_fina = 1.0 - smoothstep(VOL_NUBES_LOD.x, VOL_NUBES_LOD.y, huella * 32.0 / ef.x);
    let gruesa = mix(0.5, vol_ruido3d(t3, q / vec3<f32>(eg.x, eg.y, eg.x)).r, lod_gruesa);
    var fina = 0.5;
    if lod_fina > 0.0 && falta > 0.0 {
        fina = mix(0.5, vol_ruido3d(t3, q / vec3<f32>(ef.x, ef.y, ef.x)).g, lod_fina);
    }
    fina = mix(fina, 1.0 - fina, h);
    let e = sqrt(falta) * gruesa + falta * fina;
    d -= n.forma.erosion_fuerza * e * e * e * e;
    return d * n.perfil.densidad[i];
}
