// Ajustes del aislamiento de color. Porqué: docs/efectos/aislamiento-de-color.md §Opciones
override aislamiento_rango: i32 = 20;     // amplitud del rango de matiz (0..100 °, 0 = apagado) (§1)
override aislamiento_matiz: i32 = 0;      // grados (0..360) (§1)

// Los valores que el usuario ajustó jugando (especificación 13), constantes.
const OPC_AISLAMIENTO_SUAVIDAD: f32 = 12.0;
const OPC_AISLAMIENTO_SAT_MINIMA: f32 = 17.0;
const OPC_AISLAMIENTO_TAMANO: f32 = 5.0;
const OPC_AISLAMIENTO_EXIGENCIA: f32 = 20.0;
const OPC_AISLAMIENTO_DESATURACION: f32 = 80.0;
const OPC_AISLAMIENTO_REALCE: f32 = 30.0;

fn opc_aislamiento(exposicion: f32) -> ImgAislamiento {
    return ImgAislamiento(f32(aislamiento_matiz), f32(aislamiento_rango), OPC_AISLAMIENTO_SUAVIDAD, OPC_AISLAMIENTO_SAT_MINIMA * 0.01,
                          OPC_AISLAMIENTO_TAMANO, OPC_AISLAMIENTO_EXIGENCIA * 0.01, OPC_AISLAMIENTO_DESATURACION * 0.01,
                          OPC_AISLAMIENTO_REALCE * 0.01, exposicion);
}
