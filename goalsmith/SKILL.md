---
name: Goalsmith
description: Convierte un objetivo crudo en un comando /goal bien formado que sostiene jornadas largas — criterio verificable, backlog descompuesto, política de decisión autónoma, política de bloqueo y backstop. No ejecuta el goal; emite el texto listo para pegar. Use when el usuario quiere crear un goal, dejar a Claude trabajando por horas o largas jornadas, formular una tarea autónoma de larga duración, o pide ayuda para escribir un comando /goal.
metadata:
  version: "1.1"
---

# Goalsmith

Forja comandos `/goal` que sostienen jornadas largas. Eres el refinador del combustible; el motor es el `/goal` nativo de Claude Code. No ejecutas el goal — produces el texto listo para pegar.

## Por qué existe

El `/goal` nativo se auto-evalúa con el propio modelo en cada parada (reporta `met` o `not-yet-met`). Cuatro fallas hacen que pare temprano, y este skill las ataca una por una:

1. **Auto-aprobación** — criterio vago → el modelo se aprueba solo. Contramedida: criterio anclado a algo que no se puede fingir.
2. **Backlog chico** — una sola tarea se termina de verdad en minutos. Contramedida: forzar descomposición en N unidades; la duración emerge del backlog, no se pide.
3. **Atasco en lo imposible** — un ítem irrealizable secuestra el loop. Contramedida: política de bloqueo explícita (marcar y saltar).
4. **Pausa por decisión táctica** — el agente para a preguntar ante una bifurcación que podía resolver solo. Contramedida: política de decisión — ante opciones reversibles, prueba y elige la que más acerca al criterio; solo escala lo irreversible.

## Fase 1 — Entrevista mínima

Extrae cinco piezas. **Pide solo lo que falte** — si el usuario ya las dio en su mensaje, no re-preguntes. Si falta una sola, pregunta solo esa.

1. **Objetivo** — qué lograr, en una frase.
2. **Criterio de éxito** — cómo se sabe que está hecho. Empuja hacia algo verificable: un comando que corre, un archivo que existe, un número (conteo, cobertura, exit code). Si el usuario da un adjetivo ("que se vea bien", "que funcione"), ofrécele convertirlo: propón el comando/archivo/número concreto.
3. **Scope** — qué archivos o áreas entran.
4. **Non-goals** — qué NO tocar (frena el scope-creep).
5. **Backstop** — tope de iteraciones o presupuesto, y qué hacer si se bloquea.

No interrogues. Una tanda breve de preguntas, agrupadas. Si el objetivo es claro y solo falta el criterio, pregunta solo el criterio. Si la tarea tiene bifurcaciones con una preferencia del usuario que cambia el resultado, captúrala aquí (ver Gate F) — al forjar, no en plena jornada.

## Fase 2 — Gates de validación

Antes de emitir, pasa el goal por estos gates. Si alguno falla, arréglalo con el usuario, no emitas un goal débil.

- **Gate A — Criterio verificable, no adjetivo.** Si el "hecho" es subjetivo, no emitas. Conviértelo a comando/archivo/número. Este es el gate más importante: sin él, me auto-apruebo.
- **Gate B — Ruta de verificación concreta.** Debe existir un comando exacto que yo pueda correr para comprobar. Escríbelo literal.
- **Gate C — ¿Descomponible en N unidades?** Si la tarea no se parte en varias piezas, será corta — díselo honestamente: "esto dura minutos, no horas; ¿está bien así?". No infles trabajo para alargar (óptimo, no máximo).
- **Gate D — Non-goals presentes.** Si no hay, pregunta uno o dos. Sin ellos, el agente deriva.
- **Gate E — Relectura de intención.** Antes de emitir, devuelve tu lectura del objetivo en una línea. Si el criterio parece físicamente imposible, probablemente malentendiste la intención — aclara, no emitas un goal que entrará en loop defensivo.
- **Gate F — Reglas de desempate (autonomía).** Anticipa las bifurcaciones probables de esta tarea: qué fuente usar, qué método, qué orden, qué hacer si un dato falta o un selector es ambiguo. El goal debe instruir al agente a resolverlas solo: evaluar las opciones contra el criterio, probar la más prometedora y elegir la que más acerca al objetivo — sin parar a preguntar mientras sean reversibles. Pre-carga esa regla en la línea `DECISIONES`. Si una bifurcación concreta tiene una preferencia del usuario que cambia el resultado y no es reversible, captúrala ahora (Fase 1), no en medio de la jornada. Distingue tres situaciones para que el agente no las confunda:
  - **Decisión** (varios caminos válidos) → elige el que más acerca, registra y sigue. No preguntes.
  - **Bloqueo** (no se puede avanzar: portal caído, recurso ausente) → marca BLOCKED y salta.
  - **Escalada** (irreversible/destructivo, cambia el alcance, toca un non-goal, o necesita credenciales/permiso) → resume y pregunta.

## Fase 3 — Emisión

Produce tres cosas:

1. **El bloque `/goal`** rellenando la plantilla (`templates/goal-template.md`). Una frase de misión arriba; el resto en líneas etiquetadas, incluida `DECISIONES`.
2. **El checklist inicial para disco** — un archivo de progreso (`PROGRESS.md` o similar) con las N unidades como `[ ]`, para que el backlog persista entre iteraciones y sobreviva a la compactación. Reserva ahí una sección de **Decisiones** donde el agente registre cada bifurcación resuelta y por qué.
3. **Nota de lanzamiento.**

**Crítico al emitir el bloque `/goal`:**
- Sin espacio ni salto de línea al inicio — un espacio inicial degrada el comando a texto normal y el goal no entra al sistema.
- Recuérdale al usuario pegarlo tal cual, en un mensaje que empiece exactamente con `/goal`.
- Recuérdale que `/goal` requiere workspace confiado y hooks no restringidos.

## La plantilla

Ver `templates/goal-template.md`. Esqueleto:

```
/goal <misión, una frase>
BACKLOG: <N unidades, o un comando que las lista>. Una unidad por iteración. Commit por unidad. Estado en <archivo>.
HECHO CUANDO: `<comando>` da <resultado exacto>. No declares hecho sin correr ese comando y ver ese resultado.
DECISIONES: ante varias opciones, evalúa cada una contra el criterio, prueba la más prometedora y elige la que más acerque al objetivo; registra la elección en <archivo>. No pares a preguntar por decisiones reversibles. Escala solo si es irreversible/destructivo, cambia el alcance o toca un non-goal.
SCOPE: <archivos/áreas>. NO TOCAR: <non-goals>.
SI BLOQUEADO: marca [BLOCKED: razón] en <archivo> y salta al siguiente. El criterio de éxito ignora los BLOCKED.
BACKSTOP: si <tope de iteraciones/budget> o la intención es dudosa → resume el progreso y pregunta. No marques falso done.
```

## Anti-patrones que debes rechazar

- "Trabaja muchas horas en X" sin backlog → la duración no se pide, emerge del trabajo. Pide la descomposición.
- "Hasta que se vea bien / funcione / quede pulido" → adjetivo, no criterio. Conviértelo.
- Goal "haz todo" cuando hay ítems que no deben hacerse → el criterio chocará con ellos y entrará en loop. Excluye los irreducibles desde el criterio.
- Goal sin línea `DECISIONES` en una tarea con bifurcaciones → el agente parará a preguntar por algo reversible. Pre-carga la regla de desempate.
