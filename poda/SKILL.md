---
name: poda
description: Reduce código sin perder calidad, de forma recursiva — de hojas a raíz (archivo → módulo → paquete) y por pasadas hasta punto fijo. Cada recorte es un cambio chico que debe pasar la compuerta de calidad (tests, tipos, lint, comportamiento, API pública intacta) o se revierte. Mide antes y después. Usar cuando el usuario pida reducir, adelgazar, podar, compactar o simplificar código, quitar código muerto o duplicado, o bajar líneas sin romper nada.
---

# Poda

Quitar código es la mejora más barata de mantener. Pero una línea menos que rompe algo cuesta más que mil líneas de más. La poda sigue tres reglas:

1. **Menos código, mismo comportamiento.** Si el comportamiento cambia, no fue poda: fue un cambio de feature. Se revierte.
2. **Cada recorte se prueba solo.** Un recorte es un commit. Si falla la compuerta, se revierte ese commit y no otro.
3. **Recursivo hasta punto fijo.** Se poda de las hojas a la raíz, y se repite la pasada mientras deje ganancia real.

## Qué NO es poda (rechazar)

- Code golf: one-liners crípticos, nombres de una letra, ternarios anidados. Menos líneas y menos legible = peor.
- Borrar tests, comentarios de WHY, manejo de errores reales, validación de input externo o logs operativos.
- Cambiar la API pública (exports, contratos MCP/HTTP, schemas en disco, flags de CLI) sin que el usuario lo pida.
- Reescribir un módulo entero "más corto". Eso es un rewrite, con su propio riesgo; se propone aparte.
- Bajar líneas formateando (unir líneas, quitar saltos). La métrica cuenta líneas lógicas, no vale el formateador.

## Antes de empezar

1. **Alcance.** Qué se poda: repo, paquete, carpeta. Si es ambiguo, pregunta. Excluye por defecto: código generado, vendored, migraciones aplicadas, fixtures, lockfiles.
2. **Compuerta de calidad.** Encuentra los comandos reales del proyecto (lee `package.json`, `Makefile`, `pyproject.toml`, `scripts/verify*`, CLAUDE.md, CI). Necesitas como mínimo:
   - tests (`G1`)
   - typecheck o compilación (`G2`)
   - lint (`G3`), si existe
   - un chequeo de comportamiento (`G4`): suite e2e, snapshot de salida, baseline de API. Si no existe, la poda queda limitada a recortes de **riesgo bajo** (ver tabla) y lo dices.
   Si no hay tests, **no podes lógica**: solo código muerto demostrable (sin referencias + el build pasa). Avísalo antes de seguir.
3. **Línea base.** Corre la compuerta completa ANTES de tocar nada. Si ya está roja, para y repórtalo: no se poda sobre rojo, porque no sabrías qué rompiste tú.
4. **Medición inicial.** Corre `bash <skill>/medir.sh <ruta>` y guarda el resultado. Mide líneas lógicas (sin blancos ni comentarios) por archivo y el total.
5. **Rama.** Trabaja en una rama `poda/<area>`, nunca en main. Un commit por recorte: `refactor(<scope>): <qué se quitó>`.

## Taxonomía de recortes

Ordenados de menor a mayor riesgo. En cada nivel del árbol, agota los de riesgo bajo antes de subir.

| # | Recorte | Riesgo | Prueba de que es seguro |
|---|---------|--------|-------------------------|
| R1 | Código muerto: funciones, exports, archivos, ramas sin referencias | bajo | grep de referencias (incluye strings dinámicos, reflexión, config, rutas por convención) + build verde |
| R2 | Dependencias sin uso | bajo | ningún import + build y tests verdes |
| R3 | Código comentado, TODOs resueltos, flags siempre-on/siempre-off | bajo | historial git lo conserva; flag constante verificada en config |
| R4 | Redundancia local: variables de un solo uso que no aclaran, `else` tras `return`, condiciones duplicadas, casts innecesarios | bajo | tipos + tests |
| R5 | Usar lo que ya existe: reemplazar código propio por la stdlib, el framework o un helper del repo | medio | el helper cubre todos los casos (bordes: null, vacío, unicode, orden) |
| R6 | Duplicación: 2+ bloques casi iguales → una función | medio | solo si los bloques cambian juntos por la misma razón; si divergen por diseño, no se funden |
| R7 | Sobre-abstracción: interfaces con un solo implementador, wrappers que solo pasan args, factories de un solo producto, capas sin lógica | medio | ningún consumidor externo depende de la abstracción |
| R8 | Simplificar flujo: aplanar anidamiento, tabla en vez de cadena de `if`, early return | medio | tests que cubren cada rama (si una rama no tiene test, escríbelo primero) |
| R9 | Fundir módulos chicos que siempre se usan juntos | alto | API pública intacta; G4 verde |

Para R5–R9: si la rama tocada no tiene cobertura, **primero escribe el test** que fija el comportamiento actual (commit aparte, `test(<scope>): ...`), después recorta. Ese test se queda.

## El algoritmo recursivo

```
podar(nodo):
    si nodo es carpeta/módulo:
        para cada hijo, de las hojas hacia arriba:   # post-orden
            podar(hijo)
        podar_nivel(nodo)          # recortes que solo se ven a este nivel: R6, R7, R9 entre hijos
    si nodo es archivo:
        podar_nivel(nodo)          # R1–R8 dentro del archivo

podar_nivel(nodo):
    repetir:
        candidatos = buscar recortes en nodo, ordenados por (riesgo asc, ganancia desc)
        aplicados = 0
        para cada candidato:
            aplicar el recorte (un cambio, un commit)
            correr compuerta rápida (G1 acotado a lo afectado + G2)
            si verde: aplicados += 1
            si rojo:  git revert / git checkout; anotar en "Descartados" con la razón
        hasta que aplicados == 0 o la ganancia de la pasada < 1 % de las líneas del nodo

pasada_global:
    podar(raíz)
    correr compuerta COMPLETA (G1–G4)
    medir
    si la pasada quitó ≥ 1 % del total y no hubo regresión: otra pasada_global
    si no: punto fijo, terminar
```

Por qué post-orden: al podar las hojas aparece código muerto en el padre (un helper que solo usaba lo que borraste) y duplicación entre hermanos que antes estaba tapada. Por qué repetir: cada recorte puede destapar otro; se para cuando la pasada ya no deja ganancia.

Topes (backstop):
- Máximo **5 pasadas globales**. Si en la quinta sigue habiendo ganancia, reporta y pregunta.
- Un candidato que falla la compuerta **dos veces** con enfoques distintos se marca `[NO SE PODA: razón]` y no se vuelve a intentar.
- Si el recorte acumulado supera el **40 %** de un módulo, para y muestra el diff al usuario antes de seguir: a esa escala, puede que estés reescribiendo y no podando.

## Compuerta de calidad

Un recorte se queda solo si **todo** esto se cumple:

- **G1 tests**: verdes. Mismo número de tests o más (nunca menos, salvo tests de código muerto borrado, que se listan).
- **G2 tipos/compilación**: verdes, sin nuevos `any`, `@ts-ignore`, `# type: ignore`, `unsafe` ni supresiones de lint.
- **G3 lint**: sin warnings nuevos.
- **G4 comportamiento**: e2e/snapshot/baseline sin diferencias.
- **API pública**: mismo conjunto de exports, firmas y contratos. Verifícalo con el diff de exports (`git diff` de los `index`/`__init__`, o la herramienta de baseline del proyecto).
- **Legibilidad**: el recorte no sube la complejidad ciclomática de la función ni la profundidad de anidamiento. Si dudas, la versión larga y clara gana.
- **Rendimiento**: si la ruta es caliente (bucle interno, render, request), el recorte no la hace más lenta. Ante la duda, mide.

Compuerta rápida (por recorte): G1 acotado a los archivos afectados + G2.
Compuerta completa (por pasada global y al final): G1–G4 + API pública.

## Paralelización

Para repos grandes, los **hallazgos** (buscar candidatos) se paralelizan con agentes en modelo barato (`sonnet`), uno por módulo, en solo lectura y con output estructurado (`file`, `line`, `kind: R1..R9`, `evidence`, `lines_saved`). La **aplicación** de recortes es secuencial, en un solo árbol de trabajo: dos agentes podando a la vez generan conflictos y una compuerta roja no sabría a quién culpar. Antes de aplicar un R1 que vino de un agente, verifica tú las referencias: el agente ve solo su módulo y no ve quién lo importa desde fuera.

## Estado en disco

Mantén `PODA.md` en la raíz del alcance (no se commitea salvo que el usuario lo pida):

```
# Poda — <alcance>
Base: <commit> · líneas lógicas: <N>
Compuerta: G1 `<cmd>` · G2 `<cmd>` · G3 `<cmd>` · G4 `<cmd>`

## Pasadas
- P1: −<n> líneas (<x> %) · <k> recortes · compuerta completa verde
## Descartados
- <archivo:línea> R6: los dos bloques divergen por diseño (A valida, B no)
## No se poda
- <archivo> R1: se carga por nombre desde config/plugins.yaml
```

Así la poda sobrevive a la compactación del contexto y se puede retomar.

## Reporte final

1. Tabla antes/después: líneas lógicas totales y por módulo, número de archivos, dependencias.
2. Recortes por tipo (R1..R9) con líneas ganadas.
3. Compuerta completa: comandos corridos y resultado literal.
4. Descartados y "no se poda", con la razón de cada uno.
5. Propuestas fuera de alcance (rewrites, cambios de API) — solo propuestas, no aplicadas.

No declares hecho sin haber corrido la compuerta completa al final y visto que pasa.
