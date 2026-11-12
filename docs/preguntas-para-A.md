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

## 2026-11-11 (encargo B-18, F-11 a F-16)

8. **Promedio de cielo con nubes** (`fino/01` §1, «vector 1 apuntado para medir»): la luz ambiente que reciben las
   superficies en la escala común, con el día 0 a las 6000 (cúmulos grandes y altoestratos 1 / 0,5), a las 300 (cúmulos
   pequeños 1 / 0,5), a las 18000 (grandes 1,9 / 0,2) y con lluvia a las 6000. Ahora va a ojo de dos paneles
   (`OPC_CUBIERTO_*`): F-16.
9. **Umbral medio de la sombra de las nubes** (`fino/04` §6, «restando un umbral medio representativo»): ¿cuánto se resta
   a la cobertura de los cúmulos antes de multiplicar por la densidad, y cómo entran los altoestratos en la densidad
   acumulada de la tabla B? Ahora 0,35 y los altoestratos aparte.
10. **Factor reductor del bloom de niebla** (`fino/10` §«Lo que está mal» 2: «por un factor reductor y por la lluvia»): su
    valor fuera del modo de bastones, y si la opacidad que pesa la mezcla incluye las nubes. Ahora la opacidad va al
    cuadrado y sin nubes (F-11).
11. **Niebla en manchas:** forma del ruido (tamaño de las manchas, fracción del volumen con densidad llena, altura) para
    el parámetro 0,4 de la lluvia: densidad media por bloque a Y = 70 sobre una línea de 200 bloques. Ahora a ojo (F-13).
12. **Trayectoria del sol** del original: elevación del sol a las 300, 6000 y 12000 (con la inclinación de −35°). De los
    paneles sale 4°, 55° y 0°; Horizon da 17°, 90° y 12°.
13. **Color del fractal y de sus rayos de noche** (`noche-fractal`): en el panel son ámbar; en el pack, blanco azulado.
    ¿El color sale de la paleta, del efecto de bastones o de la exposición?

## 2026-11-11 (B-21, lote 1 y punto 0 del lote 2)

14. **Tope de la luz de cielo por oclusión** (`implementacion/01` §3.4): «con una oclusión del 80 % el tope ya es 0,37; por
    debajo del 60 % es 0,3». ¿«Oclusión del 80 %» es AO = 0,8 o AO = 0,2?
15. **Deriva del ruido del despeje con el día** (`fino/06` §1): ¿30 y 17 **bloques** por día (lo que dice el texto) o 30 y
    17 **unidades del ruido** por día (lo que dice la fórmula, ~2 900 bloques)?
