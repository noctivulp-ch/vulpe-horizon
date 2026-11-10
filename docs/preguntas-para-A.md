# Preguntas para A (especificador)

Lo que la especificación no aclara y B no debe inventar. Una por punto, con la sección que no basta. A responde en
`../vulpe-horizon-spec/` y el gestor avisa.

## 2026-11-10 (encargo F)

1. **Escala absoluta del término solar de las nubes** (`fino/05 §2` y §Medidos «fase total»). La tabla da el factor
   por el que se multiplica la irradiancia directa del astro, pero aplicada tal cual a las nubes (`σ_nube·forma` como
   densidad local, σ = 0,45 por bloque) los cúmulos salen blancos quemados; en la niebla la escala cuadra. ¿La radiancia
   de fuente de la nube lleva otro factor (albedo, 1/4π, «constante hemisférica» del §2) además de la fase? Mientras
   tanto va `OPC_NUBES_FASE_ESCALA = 0,05`.
2. **Escala fija del ambiente de la niebla** (`fino/05 §2`, «promedio del cielo despejado con una escala fija ... sumado a
   una base mínima»). La fase cenital ya está medida (0,5..2,5); falta cuánto vale la escala y la base mínima en la
   escala común (por ejemplo, radiancia del ambiente de la niebla al horizonte con el sol a 55° y a −12°).
3. **Fracción del ambiente que dispersa el aire** (`fino/05 §3`, «una fracción proporcional del color ambiental dinámico
   del cielo con nubes»): ¿qué fracción? Ahora `OPC_AIRE_AMBIENTE = 0,55` (la radiancia media del cielo tal cual).
4. **Color del término de dispersión múltiple con el sol bajo** (`fino/01 §3` y §Medidos D). El factor ×2 está medido,
   pero con el sol a 0°–4° nuestro lado opuesto sale naranja donde la tabla de `paridad/01` es gris azulado
   (0,049; 0,047; 0,039 a 2°). El término múltiple del original sale del promedio del cielo despejado: ¿de qué color es
   ese promedio con el sol a −4°, 0°, 2° y 4° (tres números por fila bastan)?
5. **Fractal a las 18000 del día 0** (`noche-fractal`): en el pack, mirando al cenit, aparece a la derecha una masa
   blanco-cian con aspecto de nube que no sabemos si es el fractal con otro conjunto o los cúmulos grandes del perfil
   (día 0, cuarto de 15000–21000: altoestratos 2 / 0,3 → grandes 1,9 / 0,2) iluminados por la luna. ¿Qué perfil de nubes
   y qué conjunto del fractal muestra el original a esa hora con día 0, y se ven las nubes de noche en el original?
6. **Cobertura areal de los cúmulos** (`paridad/05`, «las coberturas mayores que 1 cubren de más»): para calibrar
   `vol_cobertura` haría falta la fracción del plano cubierta por nube (y por nube densa) con el parámetro de cobertura
   a 0,5, 1, 1,5 y 1,9, sin erosión. Ahora está puesta a ojo del banco (64 % con 1).
7. **Agua: color de la dispersión** (`paridad/07 §(a)`, «partículas / turbidez 0,05»). Falta el albedo o el color de lo
   que dispersa el agua (lo que la hace azul y no negra) en la escala común: radiancia del agua profunda (> 30 bloques)
   vista desde el aire a 45° con el sol a 55°, descontado el reflejo. B-17.6 puso (0,04; 0,22; 0,68) y C-08.3 lo intentó
   con el albedo físico y salió cian claro.
