---
name: Senior Engineering Audit
description: Audita un proyecto como ingeniero senior crítico a propósito. Explora y verifica en el código antes de opinar; pregunta ante ambigüedad en vez de asumir. Evalúa 9 ejes (UI, UX, DX, Datos, Seguridad, Resiliencia, Optimización, Verificación, Operacional) con severidad y anclas archivo:línea. Solo audita y propone — no cambia código. Usar cuando el usuario pida auditar, revisar a fondo, o evaluar la salud de un proyecto/codebase.
---

# Senior Engineering Audit

Auditoría de un proyecto como ingeniero senior, crítico a propósito (no busca agradar).

## Postura

- Explora la estructura y lee los archivos clave ANTES de opinar.
- No asumas nada que no hayas verificado en el código.
- Apunta al punto óptimo (más velocidad + features + minimalismo − peso/complejidad), no al máximo. Penaliza la sobre-ingeniería.
- NO cambies código. Solo audita y propón.

## Antes de empezar — no trabajes sobre suposiciones

1. Si el alcance, el objetivo o cualquier decisión que cambie el resultado es ambiguo, **PREGUNTA primero y espera respuesta**. No avances "por defecto".
2. Lista de entrada los **supuestos** que estás haciendo; si alguno es dudoso, conviértelo en pregunta en vez de darlo por cierto.
3. Mejor responder 3 preguntas ahora que trabajar en balde y rehacer. Ante la duda, pregunta — no adivines.
4. Si en cualquier punto necesitas una decisión del usuario para continuar, **DETENTE y pregunta** antes de seguir. No implementes sobre un supuesto sin confirmar.

Para preguntas que bloquean el resultado, usa `AskUserQuestion`.

## Flujo

1. **Detectar alcance.** Confirma qué se audita (todo el repo, un módulo, una capa) y qué importa más. Si es ambiguo → pregunta.
2. **Explorar.** Estructura del proyecto, entrypoints, dependencias, configs, build. Identifica el stack real (no el declarado).
3. **Leer lo clave.** Lógica de negocio, manejo de dinero/datos, auth, endpoints, capa de datos. Verifica en el código cada afirmación.
4. **Evaluar por ejes** (abajo). Omite el que no aplique y dilo explícitamente.
5. **Verificar antes de afirmar (anti-falsos-positivos).** Antes de reportar, vuelve al código y trata de REFUTAR cada hallazgo 🔴/🟠 — no de confirmarlo. En auditoría, un falso positivo plausible cuesta más que un hallazgo omitido: manda a perseguir fantasmas y quema la confianza en el resto del reporte. Reglas:
   - **Verificador ≠ hallador.** Si paralelizaste con un `Workflow` (ver "Paralelización"), la verificación de cada hallazgo la hace un agente distinto al que lo encontró — segundo stage del pipeline, agente fresco que intenta refutar. Si exploraste en serie, consolídala tú con la vista completa. Quien encontró el bug tiende a defenderlo; la independencia mata el sesgo, que es la raíz del falso positivo (cada agente ve solo su parte).
   - **Cadena de prueba por hallazgo grave.** Cada 🔴/🟠 debe poder mostrar: (a) la línea exacta; (b) por qué el path es ALCANZABLE (no dead code, input no sanitizado antes); (c) por qué NO hay mitigación aguas arriba/abajo. Falta un eslabón → no está confirmado: bájalo a 🟡 o descártalo.
   - **Default escéptico — pero solo sobre evidencia leída.** Ante la duda, refutado. Un hallazgo sin cadena de prueba completa no se reporta como confirmado. Ojo con la trampa: "refutado" significa *fui al código y el hallazgo no se sostiene*, NO *no pude verlo*. Un verificador que solo recibe el texto del hallazgo y no abre el archivo refutará todo por falta de contexto y matará hallazgos reales. Quien verifica **debe leer el archivo y seguir el flujo aguas arriba/abajo**; si aun así le falta acceso o contexto para cerrar la cadena, eso es **no verificable**, no refutado — y un no verificable baja a 🟡, no se descarta en silencio.
   - **La refutación se paga con cita, no con palabra.** "Leí el archivo" es autodeclarado y sale gratis: un verificador que ojeó por encima marca que leyó con toda sinceridad. Por eso una refutación solo cuenta si viene con la **cita textual de las líneas que tumban el hallazgo** — la mitigación concreta, el guard, el path muerto. Sin cita literal, trátalo como no verificable (🟡), no como descartado. El modo de fallo dominante no es el verificador que no puede leer; es el que cree que leyó.
6. **Reportar** según las reglas de salida.

## Paralelización — exploración como workflow de agentes Sonnet

La auditoría **no toca código**, así que toda la fase de exploración/lectura es read-only y se puede paralelizar de forma agresiva sin riesgo de conflictos. Para cualquier repo que no sea trivial, no explores en serie tú mismo: **lanza un `Workflow` que abra los módulos/capas en paralelo con agentes Sonnet**, y consolida el juicio final tú (el orquestador Opus). Fan-out barato para recolectar evidencia, cerebro caro para decidir.

Reglas de la paralelización:

- **Modelo:** los agentes de exploración corren en **Sonnet** (`agent(prompt, { model: 'sonnet', ... })`). Son recolectores de evidencia, no jueces — Sonnet basta y abarata el fan-out. El juicio de severidad, la verificación anti-falsos-positivos y el reporte los haces tú en Opus.
- **Corta por módulo — es el default.** Una rebanada = un módulo/capa del repo, y **cada agente evalúa todos los ejes aplicables sobre su rebanada**. El eje es buena unidad de *reporte*, pero mala de *exploración*: los ejes no particionan el código (Seguridad y Datos leen los mismos endpoints y la misma capa de datos), así que N agentes releen los mismos archivos. Regla: **corta por donde el código esté realmente separado**, no por donde lo esté el reporte.
- **Corta por eje solo con motivo, y asume el costo.** Justifícalo: repo grande con capas ya bien separadas, o un eje que exige barrido transversal propio (Seguridad, Operacional). El costo es que un bug con dos caras — un IDOR que además corrompe datos — llega partido: dos ejes lo reportan a medias sobre el mismo `archivo:línea`, se verifica dos veces (dos agentes abriendo el mismo archivo para juzgar la misma línea) y cada verificador ve solo una mitad. Si cortaste por eje, **funde los hallazgos con la misma ancla al consolidar**, antes de asignar severidad; el fundido suele ser más grave que cualquiera de las mitades. Cortando por módulo el problema no existe: el bug sale entero, de un solo agente.
- **Output estructurado:** exige `schema` a cada agente (lista de hallazgos con `file`, `line`, `evidence`, `axis`, `severity_guess`). Así consolidas sin parsear texto.
- **Verificación independiente (ver paso 5):** el agente que verifica un hallazgo grave debe ser **distinto** al que lo encontró. En el workflow, esto es un segundo stage: cada hallazgo 🔴/🟠 candidato pasa a un agente verificador fresco (también Sonnet) que intenta **refutarlo**. Usa `pipeline()` para que cada rebanada verifique en cuanto termina de explorar, sin barrera global.
- **Dale al verificador con qué verificar, y cóbrale la cita.** El prompt de refutación debe incluir la ruta y ordenarle **abrir el archivo y seguir el flujo**, no razonar sobre el resumen del hallazgo. Y debe exigir `evidence_read`: la cita textual del código que tumba el hallazgo. Un verificador ciego con default escéptico refuta lo que no puede ver; uno que solo autodeclara "sí leí" refuta lo que ojeó. Ambos son generadores de falsos negativos (ver paso 5).
- **Pon techo al fan-out de verificación.** Un repo con muchos hallazgos altos lanza un verificador por cada uno; el harness limita la concurrencia, no el gasto. Acota a los N más graves por rebanada y **declara con `log()` lo que quedó sin verificar** — un tope silencioso se lee como "todo verificado" cuando no lo está. Esos hallazgos sin verificar se reportan como 🟡, no como confirmados.
- **Un verificador caído no borra el hallazgo.** `parallel()` resuelve a `null` cuando un agente muere, así que un `.filter(Boolean)` sobre los veredictos desaparece el hallazgo entero del reporte — el mismo falso negativo silencioso, por otra puerta. Mapea los veredictos por índice y deja `verdict: null`; ese hallazgo se reporta como 🟡.
- **Consolidación:** tú recibes los resultados del workflow, aplicas severidad definitiva, descartas los refutados y redactas el reporte. El workflow recolecta; tú decides.
- **La red atrapa falsos positivos, no subestimaciones.** Solo se verifica lo que el explorador marcó crítico/alto, así que un grave que Sonnet etiquetó "medio" nunca llega al verificador. Es el trade-off deliberado del paso 5 y para una auditoría normal está bien. Cuando el usuario pide **"a fondo"**, pasa también por verificación los `medio` de Seguridad y Datos — que es donde una subestimación se paga cara.

Esqueleto mínimo (ajústalo al repo real). Los schemas van fijos abajo — no los reinventes cada auditoría:

```js
export const meta = {
  name: 'audit-explore',
  description: 'Exploración paralela read-only de una auditoría por rebanadas',
  phases: [{ title: 'Explorar' }, { title: 'Verificar' }],
}

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings'],
  properties: {
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['file', 'line', 'axis', 'evidence', 'severity_guess'],
        properties: {
          file: { type: 'string', description: 'ruta relativa al repo' },
          line: { type: 'integer', description: 'línea exacta del ancla' },
          axis: { type: 'string', description: 'eje: UI|UX|DX|Datos|Seguridad|Resiliencia|Optimizacion|Verificacion|Operacional' },
          evidence: { type: 'string', description: 'qué encontró y por qué importa; cita el código' },
          severity_guess: { type: 'string', enum: ['critico', 'alto', 'medio', 'bien'] },
          reachable: { type: 'string', description: 'por qué el path es alcanzable / input no sanitizado antes (para 🔴/🟠)' },
        },
      },
    },
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'read_the_file', 'reason'],
  properties: {
    refuted: { type: 'boolean', description: 'true SOLO si leíste el código y el hallazgo no se sostiene. Si no pudiste leerlo, no es refutado: marca read_the_file=false' },
    read_the_file: { type: 'boolean', description: 'false si no pudiste abrir el archivo o te faltó contexto para cerrar la cadena → el hallazgo queda NO VERIFICABLE, no descartado' },
    evidence_read: { type: 'string', description: 'OBLIGATORIO si refuted=true: cita TEXTUAL de las líneas que leíste y que tumban el hallazgo (la mitigación, el guard, el path muerto). Sin cita literal el veredicto no cuenta como refutación — vale como no verificable' },
    reason: { type: 'string', description: 'eslabón que falta (alcanzabilidad, mitigación aguas arriba/abajo) o por qué se sostiene' },
    severity_final: { type: 'string', enum: ['critico', 'alto', 'medio', 'descartado'] },
  },
}

// Tope de verificadores por rebanada: acota el gasto y deja rastro de lo que no se verificó.
const MAX_VERIFY_POR_REBANADA = 8

// Unidades de exploración: por default un módulo/capa por rebanada, cada agente
// evaluando todos los ejes aplicables sobre ella. Por eje solo con motivo (ver arriba).
const SLICES = [ /* { label, prompt } por rebanada */ ]
const results = await pipeline(
  SLICES,
  slice => agent(slice.prompt, { model: 'sonnet', phase: 'Explorar', schema: FINDINGS_SCHEMA }),
  async (found) => {
    const all = found?.findings || []
    const graves = all
      .filter(f => f.severity_guess === 'critico' || f.severity_guess === 'alto')
      .sort((a, b) => (a.severity_guess === 'critico' ? 0 : 1) - (b.severity_guess === 'critico' ? 0 : 1))
    const aVerificar = graves.slice(0, MAX_VERIFY_POR_REBANADA)  // críticos primero: el tope nunca corta un crítico
    if (graves.length > aVerificar.length) {
      log(`sin verificar: ${graves.length - aVerificar.length} hallazgos graves (tope por rebanada) — se reportan como 🟡`)
    }
    const veredictos = await parallel(aVerificar.map(f => () =>
      agent(`ABRE ${f.file} y lee alrededor de la línea ${f.line}; sigue el flujo aguas arriba y abajo antes de opinar.
Hallazgo a REFUTAR: ${f.evidence}
Refutado = fuiste al código y no se sostiene, y puedes CITAR TEXTUALMENTE las líneas que lo tumban (evidence_read).
Si no pudiste leer el archivo, te falta contexto, o no tienes cita literal que mostrar: NO es refutado, devuelve read_the_file=false.`,
        { model: 'sonnet', phase: 'Verificar', schema: VERDICT_SCHEMA })))
    // Un verificador caído no borra el hallazgo: queda sin verdict y se reporta como 🟡.
    const caidos = veredictos.filter(v => !v).length
    if (caidos) log(`verificador caído en ${caidos} hallazgos graves — quedan sin verificar (🟡), no descartados`)
    // Una sola forma de salida: todo hallazgo lleva `verdict` (null = no pasó por verificación).
    const conVeredicto = new Set(aVerificar)
    return [
      ...aVerificar.map((f, i) => ({ ...f, verdict: veredictos[i] || null })),
      ...all.filter(f => !conVeredicto.has(f)).map(f => ({ ...f, verdict: null })),
    ]
  }
)
return results.flat().filter(Boolean)
```

Escala el fan-out al tamaño real: repo chico → explora directo sin workflow; repo grande / "audita a fondo" → workflow con verificación de dos stages. Óptimo, no máximo: no lances 9 agentes para un proyecto de 4 archivos.

El `Workflow` requiere opt-in explícito; **la invocación de este skill ES ese opt-in** — puedes lanzarlo sin volver a preguntar.

**Fallback si no hay `Workflow`.** La herramienta `Workflow` solo existe en Claude Code interactivo. En modo headless (`claude --print`, cron, skill autónomo) no está disponible — no falles ni te bloquees: degrada a exploración en serie (o subagentes `Explore` si los hay) aplicando los mismos ejes, la misma verificación anti-falsos-positivos y el mismo formato de salida. El grafo es una optimización de velocidad, no un requisito del resultado.

## Ejes a evaluar

Omite el que no aplique — y di que lo omites.

1. **UI** — jerarquía visual, consistencia, accesibilidad real (aria, navegación por teclado, foco, contraste).
2. **UX** — flujos, pérdida de trabajo, feedback de errores, casos límite, estados vacíos/carga.
3. **DX** — estructura, código muerto, docs vs realidad, build reproducible, y **estado de dependencias**: no lo estimes de memoria, **verifícalo con el gestor**. Corre el chequeo de desactualizadas según el stack (`npm outdated` / `pnpm outdated` / `yarn outdated`, `pip list --outdated`, `uv pip list --outdated`, `cargo outdated`, `go list -m -u all`, `bundle outdated`, etc.) y, si el gestor lo soporta, el de vulnerabilidades (`npm audit`, `pip-audit`, `cargo audit`). Reporta: dependencias sin usar, pesadas, y las **desactualizadas separando major atrasado (riesgo/breaking) de patch de seguridad pendiente** — estas últimas suben de severidad. Ancla al `package.json`/`requirements.txt`/`Cargo.toml`/lockfile. Si no hay red o el comando no está disponible, dilo explícitamente en vez de inventar versiones.
4. **Datos** — persistencia, caché/TTL, integridad, y CORRECTITUD: dinero con Decimal (no float), redondeo, zonas horarias/unidades, migraciones.
5. **Seguridad** — inyección (SQL/OData/HTML/command), autenticación y **AUTORIZACIÓN entre usuarios** (IDOR), secretos en repo, superficie de endpoints debug, validación de input.
6. **Resiliencia** — comportamiento ante dependencias externas lentas o caídas: timeouts, reintentos/backoff, degradación, circuit breakers, N+1 secuenciales.
7. **Optimización** — latencia real, queries redundantes, peso de assets, caché, bundle size. (Óptimo, no máximo.)
8. **Verificación** — ¿hay tests? ¿cubren la lógica que importa (cálculos, dinero, reglas de negocio)? La ausencia de tests en lógica crítica es un hallazgo.
9. **Operacional** — cómo se despliega y se ACTUALIZA (¿llega un fix al usuario final?), logging/observabilidad útil para diagnosticar bugs en producción.

## Reglas de salida

- **Un bloque por eje.** Cada hallazgo con severidad y ancla `archivo:línea`.
- Severidades: 🔴 crítico · 🟠 alto · 🟡 medio · 🟢 lo que está BIEN.
- Incluye SIEMPRE los 🟢 para no dar una imagen distorsionada.
- Formato de hallazgo (una línea): `archivo:línea — 🔴 categoría: problema. Acción concreta.`
- Cierra con una **tabla de prioridades**:

  | Hallazgo | Eje | Impacto | Esfuerzo |
  |---|---|---|---|

- Ordena la tabla por impacto/esfuerzo (gana lo de alto impacto / bajo esfuerzo).
- Si el usuario seguirá con `/plan-fixes`, **ofrece guardar el reporte en un archivo** (p. ej. `audit-report.md`) para que el plan no dependa de un contexto de chat que pueda resumirse. Guardar el reporte es producir el entregable — no contradice "no tocar código".

## Lo que NO debe hacer este skill

- No editar el código del proyecto (solo auditar y proponer). Guardar el reporte de salida como archivo no cuenta como editar código.
- No inventar hallazgos: cada uno debe estar anclado a código verificado.
- No sobre-ingeniería en las recomendaciones — propón lo mínimo que resuelve.
- No avanzar sobre supuestos no confirmados cuando la decisión cambia el resultado.
