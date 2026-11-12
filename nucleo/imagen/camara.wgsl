// Ajustes de cámara (19), todos apagados por defecto: zoom, viñeta, grano, bandas de cine y líneas de encuadre.
// Funciones puras sin lecturas de textura. Porqué: docs/efectos/camara-y-juego.md §«Ajustes de cámara»

// Zoom hacia el centro: 0 no cambia nada, 1 amplía ×4.
fn img_zoom(uv: vec2<f32>, zoom: f32) -> vec2<f32> {
    return vec2<f32>(0.5) + (uv - vec2<f32>(0.5)) / (1.0 + 3.0 * zoom);
}

// Viñeta de caída muy suave que deja intacto el centro (más de la mitad del radio). `fuerza` 0..1.
fn img_vineta(uv: vec2<f32>, aspecto: f32, fuerza: f32) -> f32 {
    let q = (uv - vec2<f32>(0.5)) * vec2<f32>(aspecto / max(aspecto, 1.0), 1.0) * 2.0;
    let r = length(q) / 1.41421356;
    return 1.0 - fuerza * smoothstep(0.5, 1.0, r) * smoothstep(0.5, 1.0, r);
}

// Grano blanco por canal, proporcional al brillo (sRGB, tras el tonemap). `ruido` 0..1 por canal; `fuerza` 0..1.
fn img_grano(c: vec3<f32>, ruido: vec3<f32>, fuerza: f32) -> vec3<f32> {
    return c + (ruido - 0.5) * c * (0.5 * fuerza);
}

// Bandas de cine: 0 dentro de las franjas (por fracción de pantalla, arriba y abajo y a los lados).
fn img_bandas(uv: vec2<f32>, alto: f32, ancho: f32) -> f32 {
    let dentro = uv.y >= alto * 0.5 && uv.y <= 1.0 - alto * 0.5 && uv.x >= ancho * 0.5 && uv.x <= 1.0 - ancho * 0.5;
    return select(0.0, 1.0, dentro);
}

// Líneas de la regla de tercios, de un píxel: 1 sobre la línea.
fn img_tercios(pixel: vec2<f32>, resolucion: vec2<f32>) -> f32 {
    let d = abs(fract(pixel / resolucion * 3.0 + vec2<f32>(0.5)) - vec2<f32>(0.5)) * resolucion / 3.0;
    let borde = pixel > vec2<f32>(1.0) & pixel < resolucion - vec2<f32>(1.0);
    return select(0.0, 1.0, any(d < vec2<f32>(0.5) & borde));
}

// Desenfoque de movimiento: el desplazamiento en pantalla de este píxel desde el fotograma anterior, normalizado al
// tiempo de un fotograma a 60 Hz y comprimido si es enorme. `cantidad` 0..1.
fn img_movimiento(uv: vec2<f32>, uv_antes: vec2<f32>, dt: f32, cantidad: f32) -> vec2<f32> {
    let v = (uv - uv_antes) * (cantidad * (1.0 / 60.0) / max(dt, 1e-3));
    return v / (1.0 + length(v) * 4.0);
}
