// Ajustes de la vegetación ondulante. Porqué: docs/efectos/vegetacion-ondulante.md §Opciones
// Opciones «ondulacion» y «ondulacion_fuerza»: con [vertex] desactivado en el manifiesto van como override sin
// entrada de menú (el comprobador exige que cada opción sea un override de alguna etapa). Al activar [vertex], volver
// a declararlas en el manifiesto (texto en docs/efectos/vegetacion-ondulante.md).
override ondulacion: bool = true;
override ondulacion_fuerza: f32 = 1.0;

const OPC_VIENTO_VELOCIDAD: f32 = 1.0;
const OPC_MAT_PLANTA_ALTA_ARRIBA: u32 = 8u;     // mitad superior de las plantas de dos bloques
