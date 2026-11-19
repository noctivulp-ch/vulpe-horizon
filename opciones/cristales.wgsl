// Constantes y ajustes de «el tiempo en los cristales» (subsistema 27, sin opciones nuevas en el menú 64/64).
// Porqué: docs/efectos/tiempo-en-los-cristales.md

const OPC_TAG_CRISTAL: u32 = 1u;                 // bit 0 de MaterialInput.tags ([[tags]] id = "cristal")
const OPC_CRISTAL_REJILLA: f32 = 32.0;           // resolución base: 32 texeles por bloque (27 §Detalle)

// Interruptor maestro del pack (sin mod; con mod manda [cristales] en config/vulpe-horizon.toml).
const OPC_CRISTAL_ACTIVO: bool = true;
const OPC_CRISTAL_NIVEL_DEFECTO: f32 = 1.0;      // 0 apagada, 0,5 ligera, 1,0 normal, 1,5 intensa
const OPC_CRISTAL_ESTILO_REGUEROS: bool = false; // false = gotas a tirones, true = regueros verticales (27 §1)

// Lluvia y secado (27 §1)
const OPC_CRISTAL_CIELO_MIN: f32 = 0.85;         // luz de cielo ~14/15: bajo alero corto moja, bajo porche hondo no
const OPC_CRISTAL_CIELO_MAX: f32 = 0.93;
const OPC_CRISTAL_VIENTO_BARLOVENTO: f32 = 0.45; // más gotas en caras hacia el viento, menos a sotavento
const OPC_CRISTAL_VIENTO_INCLINACION: f32 = 0.35;// inclinación lateral de las gotas que bajan con viento
const OPC_CRISTAL_DIST_INICIO: f32 = 18.0;       // atenuación por distancia para evitar parpadeo subpíxel
const OPC_CRISTAL_DIST_FIN: f32 = 44.0;
const OPC_CRISTAL_GOTA_REFRACCION: f32 = 0.085;  // desvío óptico fuerte en cada gota (lente en 22)
const OPC_CRISTAL_GOTA_ESPECULAR: f32 = 1.90;    // brillo especular del sol/luna/cielo/luz cercana sobre la gota
const OPC_CRISTAL_GOTA_CAUSTICA: f32 = 0.65;     // brillo interno en la parte baja de la lente de agua
const OPC_CRISTAL_GOTA_BORDE: f32 = 0.44;        // borde oscuro por reflexión interna en el contorno de la gota
const OPC_CRISTAL_MOJADO_F0_EXTRA: f32 = 0.045;  // el cristal mojado refleja un poco más
const OPC_CRISTAL_SECADO_RASTRO: vec2<f32> = vec2<f32>(0.0, 0.28);  // 0..8 s: primero se secan los rastros
const OPC_CRISTAL_SECADO_PEQUENAS: vec2<f32> = vec2<f32>(0.18, 0.62);// 5..18 s: luego las gotas pequeñas
const OPC_CRISTAL_SECADO_GRANDES: vec2<f32> = vec2<f32>(0.50, 1.0); // 15..30 s: al final las grandes

// Escarcha en el frío (27 §2)
const OPC_CRISTAL_ESCARCHA_INTERIOR: bool = false; // respaldo sin mod: escarcha también por dentro
const OPC_CRISTAL_ESCARCHA_CIELO_MIN: f32 = 0.68;  // exposición al aire frío (incluso bajo aleros)
const OPC_CRISTAL_ESCARCHA_CIELO_MAX: f32 = 0.88;
const OPC_CRISTAL_ESCARCHA_INT_PESO: f32 = 0.65;   // fuerza relativa en cara interior cuando está activada
const OPC_CRISTAL_ESCARCHA_ALCANCE: f32 = 0.24;    // penetración suave desde el borde (bloques)
const OPC_CRISTAL_ESCARCHA_ESQUINA: f32 = 0.34;    // radio algo mayor en las esquinas
const OPC_CRISTAL_ESCARCHA_JUNTA_PESO: f32 = 0.22; // delicada en juntas interiores entre cristales contiguos
const OPC_CRISTAL_ESCARCHA_COLOR: vec3<f32> = vec3<f32>(0.86, 0.95, 1.0); // blanca azulada cristalina (lineal)
const OPC_CRISTAL_ESCARCHA_OPACIDAD: f32 = 0.48;   // translúcida: deja ver a través difuso
const OPC_CRISTAL_ESCARCHA_DESENFOQUE: f32 = 0.011;// radio de desenfoque de lo de detrás (UV de pantalla)
const OPC_CRISTAL_ESCARCHA_TEMP_NIEVE: f32 = 0.15; // umbral de temperatura de nieve en Minecraft (sin mod)

// Copos y montón de nieve (27 §3)
const OPC_CRISTAL_NIEVE_COLOR: vec3<f32> = vec3<f32>(0.92, 0.95, 1.0); // blanco frío en lineal
const OPC_CRISTAL_NIEVE_MONTON_MIN: f32 = 4.0;     // altura mínima del montón inferior en texeles de 32
const OPC_CRISTAL_NIEVE_MONTON_MAX: f32 = 6.0;     // altura máxima del montón inferior en texeles de 32
const OPC_CRISTAL_NIEVE_JUNTA_PESO: f32 = 0.45;    // altura reducida en juntas superiores sin alféizar sólido
const OPC_CRISTAL_NIEVE_OPACIDAD_COPO: f32 = 0.90;
const OPC_CRISTAL_NIEVE_OPACIDAD_MONTON: f32 = 0.96;

// Vaho del aliento (27 §4)
const OPC_CRISTAL_ALIENTO_ACTIVO: bool = true;     // respaldo sin mod
const OPC_CRISTAL_VAHO_DIST: f32 = 1.5;            // distancia máxima cámara-cristal en bloques
const OPC_CRISTAL_VAHO_RADIO: f32 = 1.0;           // radio máximo de la mancha (~1 bloque)
const OPC_CRISTAL_VAHO_PERIODO: f32 = 3.5;         // pulso de respiración en segundos (~3–4 s)
const OPC_CRISTAL_VAHO_COLOR: vec3<f32> = vec3<f32>(0.90, 0.94, 0.98); // condensación lisa, más clara que la escarcha
const OPC_CRISTAL_VAHO_OPACIDAD: f32 = 0.62;

// Arena tras tormenta en bioma seco (27 §5)
const OPC_CRISTAL_ARENA_BARLOVENTO: f32 = 0.40;    // más polvo/arena en caras hacia el viento
const OPC_CRISTAL_ARENA_VELO_MAX: f32 = 0.52;      // opacidad máxima del velo fino de polvo
const OPC_CRISTAL_ARENA_GRANO_PESO: f32 = 0.24;    // aporte sutil de granos en la rejilla de 32
const OPC_CRISTAL_ARENA_COLOR_AMARILLA: vec3<f32> = vec3<f32>(0.68, 0.59, 0.42); // polvo de desierto/sabana (lineal)
const OPC_CRISTAL_ARENA_COLOR_ROJA: vec3<f32> = vec3<f32>(0.52, 0.30, 0.18);     // polvo terracota de mesa/badlands (lineal)

// Convierte el código 0..3 del mod (apagada / ligera / normal / intensa) a multiplicador de intensidad.
fn opc_cristal_escala_nivel(codigo: u32) -> f32 {
    switch codigo {
        case 0u: { return 0.0; }
        case 1u: { return 0.55; }
        case 2u: { return 1.0; }
        default: { return 1.5; }
    }
}
