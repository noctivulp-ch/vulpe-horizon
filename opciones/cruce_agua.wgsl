// Cruzar la superficie del agua con la cámara. Porqué: docs/efectos/agua.md §«Cruzar la superficie»
const OPC_AGUA_CRUCE: f32 = 0.2;            // bloques de la superficie en que se decide por píxel si se está bajo el agua
const OPC_AGUA_NIVEL: f32 = 0.888889;       // alto de la superficie de una fuente dentro de su bloque (8/9)
const OPC_AGUA_SONDA: f32 = 0.03;           // separación en v de la sonda que confirma la superficie
const OPC_AGUA_ESTADO_BASE: f32 = 512.0;    // se guarda floor(nivel) + base (> 0; entero exacto en media precisión)
const OPC_AGUA_SOMBRA_MARGEN: f32 = 0.1;    // bloques por encima y por debajo del nivel que se miran en el mapa de sombras
const OPC_AGUA_SOMBRA_APARTE: f32 = 0.8;    // bloques hacia la luz: fuera de la sombra del jugador
const OPC_AGUA_ENTRADA_CUEVA: f32 = 16.0;   // bloques sobre la cámara que se supone la superficie al entrar sin luz de cielo (fino/07 §7)
const OPC_AGUA_ENTRADA_SIN_CIELO: f32 = 0.1;  // luz de cielo en la cámara por debajo de la cual se entra «desde una cueva»
