// El tiempo atmosférico como datos: horario de la niebla y perfiles del tiempo diario. En el original son ajustables
// (8 densidades por hora, perfiles propios); aquí, constantes con nombre para un preset o el mod nativo, sin opciones de
// menú (van 58 de 64). Porqué: docs/efectos/niebla-y-nubes.md §«Tiempo como datos»

// Horario de la niebla: densidad relativa al amanecer, a mediodía, al atardecer y de noche (x, y, z, w).
const OPC_NIEBLA_HORARIO_UNIFORME: vec4<f32> = vec4<f32>(0.06, 0.0, 0.1, 0.38);
const OPC_NIEBLA_HORARIO_MANCHAS: vec4<f32> = vec4<f32>(0.5, 0.0, 0.0, 0.15);
const OPC_NIEBLA_HORARIO_TRANSICION: f32 = 0.08;   // fracción del día que tarda en pasar de una franja a otra

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
// Fundido entre un perfil y el siguiente: tramo del cuarto de día en que se mezclan (smoothstep de inicio a fin).
const OPC_TIEMPO_FUNDIDO: vec2<f32> = vec2<f32>(0.2, 0.8);
