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
   - **Default escéptico.** Ante la duda, refutado. Un hallazgo sin cadena de prueba completa no se reporta como confirmado.
6. **Reportar** según las reglas de salida.

## Paralelización — exploración como workflow de agentes Sonnet

La auditoría **no toca código**, así que toda la fase de exploración/lectura es read-only y se puede paralelizar de forma agresiva sin riesgo de conflictos. Para cualquier repo que no sea trivial, no explores en serie tú mismo: **lanza un `Workflow` que abra los ejes/capas en paralelo con agentes Sonnet**, y consolida el juicio final tú (el orquestador Opus). Fan-out barato para recolectar evidencia, cerebro caro para decidir.

Reglas de la paralelización:

- **Modelo:** los agentes de exploración corren en **Sonnet** (`agent(prompt, { model: 'sonnet', ... })`). Son recolectores de evidencia, no jueces — Sonnet basta y abarata el fan-out. El juicio de severidad, la verificación anti-falsos-positivos y el reporte los haces tú en Opus.
- **Fan-out por eje/capa:** un agente por eje aplicable (o por capa del repo si es más natural). Cada agente explora SOLO su parte, lee los archivos clave de su dominio y devuelve **hallazgos crudos anclados a `archivo:línea`** — sin asignar severidad final ni redactar el reporte.
- **Output estructurado:** exige `schema` a cada agente (lista de hallazgos con `file`, `line`, `evidence`, `axis`, `severity_guess`). Así consolidas sin parsear texto.
- **Verificación independiente (ver paso 5):** el agente que verifica un hallazgo grave debe ser **distinto** al que lo encontró. En el workflow, esto es un segundo stage: cada hallazgo 🔴/🟠 candidato pasa a un agente verificador fresco (también Sonnet) que intenta **refutarlo**. Usa `pipeline()` para que cada eje verifique en cuanto termina de explorar, sin barrera global.
- **Consolidación:** tú recibes los resultados del workflow, aplicas severidad definitiva, descartas los refutados y redactas el reporte. El workflow recolecta; tú decides.

Esqueleto mínimo (ajústalo al repo real). Los schemas van fijos abajo — no los reinventes cada auditoría:

```js
export const meta = {
  name: 'audit-explore',
  description: 'Exploración paralela read-only de una auditoría por ejes',
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
  required: ['refuted', 'reason'],
  properties: {
    refuted: { type: 'boolean', description: 'true si NO hay cadena de prueba completa (default escéptico)' },
    reason: { type: 'string', description: 'eslabón que falta (alcanzabilidad, mitigación aguas arriba/abajo) o por qué se sostiene' },
    severity_final: { type: 'string', enum: ['critico', 'alto', 'medio', 'descartado'] },
  },
}

const AXES = [ /* solo los ejes aplicables, con su prompt de exploración */ ]
const results = await pipeline(
  AXES,
  ax => agent(ax.prompt, { model: 'sonnet', phase: 'Explorar', schema: FINDINGS_SCHEMA }),
  found => parallel((found.findings || [])
    .filter(f => f.severity_guess === 'critico' || f.severity_guess === 'alto')
    .map(f => () => agent(`Intenta REFUTAR este hallazgo: ${f.evidence} (${f.file}:${f.line}). Default: refutado si no hay cadena de prueba completa.`,
      { model: 'sonnet', phase: 'Verificar', schema: VERDICT_SCHEMA }).then(v => ({ ...f, verdict: v }))))
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
