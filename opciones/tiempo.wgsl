// El tiempo atmosférico como datos: horario de la niebla y perfiles del tiempo diario. En el original son ajustables
// (8 densidades por hora, perfiles propios); aquí, constantes con nombre para un preset o el mod nativo, sin opciones de
// menú (van 58 de 64). Porqué: docs/efectos/niebla-y-nubes.md §«Tiempo como datos»

// Horario de la niebla: parámetro horario al amanecer, a mediodía, al atardecer y de noche (x, y, z, w).
// La densidad efectiva en el raymarch es el cubo de este parámetro (paridad/05 y fino/05 §1, §4).
const OPC_NIEBLA_HORARIO_UNIFORME: vec4<f32> = vec4<f32>(0.01, 0.0, 0.05, 0.2);
const OPC_NIEBLA_HORARIO_MANCHAS: vec4<f32> = vec4<f32>(0.05, 0.0, 0.0, 0.05);
const OPC_NIEBLA_HORARIO_TRANSICION: f32 = 0.08;   // fracción del día que tarda en pasar de una franja a otra

fn opc_niebla_horario_uniforme() -> vec4<f32> {
    let m = opc_estilo_niebla_horaria();
    return vec4<f32>(
        OPC_NIEBLA_HORARIO_UNIFORME.x * m.mult_dia,
        OPC_NIEBLA_HORARIO_UNIFORME.y * m.mult_dia,
        OPC_NIEBLA_HORARIO_UNIFORME.z * m.mult_dia,
        OPC_NIEBLA_HORARIO_UNIFORME.w * m.mult_noche,
    );
}

fn opc_niebla_horario_manchas() -> vec4<f32> {
    let m = opc_estilo_niebla_horaria();
    return vec4<f32>(
        OPC_NIEBLA_HORARIO_MANCHAS.x * m.mult_manchas_dia,
        OPC_NIEBLA_HORARIO_MANCHAS.y * m.mult_manchas_dia,
        OPC_NIEBLA_HORARIO_MANCHAS.z * m.mult_manchas_dia,
        OPC_NIEBLA_HORARIO_MANCHAS.w * m.mult_manchas_noche,
    );
}

// Los once perfiles del tiempo diario (paridad/05 §Tiempo diario): cobertura y densidad de los cúmulos pequeños, los
// grandes y los altoestratos. 0 despejado.
const OPC_TIEMPO_COBERTURA = array<vec3<f32>, 11>(
    vec3<f32>(0.0, 0.0, 0.0),   // despejado
    vec3<f32>(1.0, 0.0, 0.0),   // cúmulos pequeños
    vec3<f32>(0.0, 1.0, 1.0),   // grandes y altoestratos
    vec3<f32>(0.0, 0.0, 2.0),   // altoestratos cubiertos
    vec3<f32>(0.0, 1.9, 0.0),   // grandes extendidos
    vec3<f32>(1.0, 0.1, 1.0),   // pequeños y altoestratos
    vec3<f32>(0.0, 1.1, 0.0),   // solo cúmulos grandes
    vec3<f32>(1.0, 0.0, 1.5),   // pequeños tenues y altoestratos
    vec3<f32>(0.0, 0.0, 1.0),   // solo altoestratos
    vec3<f32>(1.4, 0.0, 0.0),   // pequeños abundantes
    vec3<f32>(1.0, 1.0, 0.0),   // pequeños y grandes
);
const OPC_TIEMPO_DENSIDAD = array<vec3<f32>, 11>(
    vec3<f32>(0.0, 0.0, 0.0),
    vec3<f32>(0.5, 0.0, 0.0),
    vec3<f32>(0.0, 0.5, 0.5),
    vec3<f32>(0.0, 0.0, 0.3),
    vec3<f32>(0.0, 0.2, 0.0),
    vec3<f32>(0.5, 0.5, 0.1),
    vec3<f32>(0.0, 0.5, 0.0),
    vec3<f32>(0.1, 0.1, 0.25),
    vec3<f32>(0.0, 0.0, 0.5),
    vec3<f32>(0.5, 0.0, 0.0),
    vec3<f32>(0.25, 0.5, 0.0),
);
// Orden de los perfiles por cuarto de día desde el día 0; a partir del 18.º se repiten los últimos 14.
const OPC_TIEMPO_SECUENCIA = array<u32, 18>(1u, 2u, 3u, 4u, 5u, 6u, 1u, 7u, 8u, 6u, 1u, 4u, 1u, 4u, 9u, 10u, 8u, 0u);
const OPC_TIEMPO_SECUENCIA_REPITE_DESDE: u32 = 4u;
// Ambiente con nubes (F-16), a ojo de los paneles del banco a falta del promedio medido (pregunta para A): rampas de la
// cobertura del perfil a la fracción de cielo con nube y a la forma media (ajustadas a fino/05 P6: 9 % y 0,01 con 0,5;
// 78 % y 0,2 con 1; 100 % y 0,56 con 1,5); extinción de la luz del astro a través de la nube por unidad de espesor
// (forma media × densidad), y parte del cielo despejado que se sigue viendo entre y a través de ellas.
const OPC_CUBIERTO_CON_NUBE: vec2<f32> = vec2<f32>(0.35, 1.3);
const OPC_CUBIERTO_MEDIA: vec2<f32> = vec2<f32>(0.5, 2.3);
const OPC_CUBIERTO_EXTINCION: f32 = 8.0;
const OPC_CUBIERTO_CIELO: f32 = 0.5;

// Fundido entre un perfil y el siguiente: tramo del cuarto de día en que se mezclan (smoothstep de inicio a fin).
const OPC_TIEMPO_FUNDIDO: vec2<f32> = vec2<f32>(0.95, 1.0);
