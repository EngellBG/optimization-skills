---
name: Remediation Plan
description: Diseña un PLAN por fases para atacar los hallazgos de una auditoría previa — todavía NO implementa. Norte = punto óptimo, no máximo; penaliza la sobre-ingeniería. Primero pregunta las decisiones de alcance que cambian el plan de raíz y se detiene a esperar respuesta. Cada fase es entregable por sí sola, ordenada por riesgo→dependencia, con métrica y esfuerzo. Usar tras /audit, o cuando el usuario pida planear cómo atacar hallazgos/deuda técnica sin codear aún.
---

# Remediation Plan

Diseña el PLAN para atacar los hallazgos (típicamente de un reporte de `/audit`). **No implementa nada** en este paso.

## Postura

Ingeniero senior. Norte = **PUNTO ÓPTIMO, no máximo**:

`(más velocidad + mejores features + minimalismo) − (peso de archivo + dependencias + complejidad)`

Penaliza la sobre-ingeniería: prefiere la solución que captura ~90% del beneficio con la menor carga.

## Entrada

Los hallazgos de la auditoría previa (el reporte ya generado). **Prefiere leerlo desde un archivo si existe** (p. ej. `audit-report.md`): el contexto de chat puede haberse resumido y degradado los hallazgos, y el plan saldría de datos incompletos. Si no hay reporte ni en archivo ni en contexto, pídelo o corre `/audit` primero.

## Primero — no planees sobre suposiciones

Antes de escribir una sola fase:

1. Identifica las **decisiones de alcance que CAMBIAN el plan de raíz**. Ejemplos:
   - ¿Se agrega un paso de build?
   - ¿Despliegue local o compartido?
   - ¿Se toca tal dependencia o se evita?
   - ¿Hay algo que NO debamos cambiar?
2. Haz esas preguntas y **DETENTE a esperar respuesta**. No fijes el plan con decisiones colgando "por defecto".
3. Mejor responder 3 preguntas ahora que planear algo que haya que rehacer.

Usa `AskUserQuestion` para las decisiones que bloquean el plan.

## Luego — con el alcance cerrado, escribe el plan

- Divídelo en **FASES**, cada una entregable por sí sola (se puede parar en cualquier punto y aun así haber ganado algo).
- Ordénalas por **riesgo→dependencia** (lo trivial y de bajo riesgo primero).
- Cada fase incluye:
  - **Objetivo**
  - **Archivos/áreas afectadas**
  - **Métrica esperada** (ej. −92 MB, 250→135 KB, N→⌈N/40⌉ requests)
  - **Esfuerzo** (trivial / bajo / medio / alto)
- Marca los **QUICK-WINS** (bajo riesgo, alto valor) que se pueden hacer ya.
- Marca como **CONDICIONAL** toda fase que dependa de una decisión del usuario, y di de qué decisión depende.
- Cierra con la **secuencia recomendada** (Fase 0 → 1 → 2 …).

## Tras la aprobación — forja el goal

El plan no es el destino: es el combustible para un `/goal` que ejecuta la remediación en jornada autónoma. Cuando el usuario **apruebe el plan** (tal cual o con ajustes), no te pongas a implementar — **encadena con el skill `goalsmith`** para emitir el comando `/goal` listo para pegar.

- **No reimplementes goalsmith.** Invócalo y pásale el plan ya masticado como insumo. El plan trae casi todo lo que su entrevista extrae, así que goalsmith salta preguntas y va directo a forjar:

  | Del plan | → línea del goal |
  |---|---|
  | Fases entregables | `BACKLOG` — una unidad por iteración, commit por unidad |
  | Métrica esperada por fase | `HECHO CUANDO` — criterio verificable, con el comando exacto |
  | Archivos/áreas afectadas | `SCOPE` |
  | Decisión "no tocar" del alcance | `NO TOCAR` / non-goals |
  | Secuencia recomendada | orden del `BACKLOG` |
  | Quick-wins | primeras unidades del backlog |

- **El goal debe salir potente — óptimo y rápido, no tímido.** Al forjarlo, asegura que habilite:
  - **Autonomía:** línea `DECISIONES` cargada — ante bifurcaciones reversibles el agente prueba y elige lo que más acerca al criterio, sin parar a preguntar. Solo escala lo irreversible o lo que toque un non-goal.
  - **Paralelización de la implementación:** las fases que sean **independientes entre sí** (sin dependencia de datos ni de archivos) pueden atacarse en paralelo con un `Workflow` de agentes. Aquí **sí** aplica **worktree isolation** — cada agente escribe en su propia copia del repo para no pisar a los demás (requiere que el proyecto sea repo git). Las fases con dependencia van en serie, en el orden de la secuencia recomendada. Esto es lo contrario de la planeación: planear es read-only y no usa worktree; **ejecutar sí escribe, y por eso el worktree entra aquí.**
  - **Backstop claro:** tope de iteraciones/presupuesto y qué hacer si se bloquea, para que no entre en loop ni marque falso done.

- Deja que goalsmith aplique sus propios gates (criterio verificable, non-goals presentes, relectura de intención). Tú solo garantizas que el insumo que le pasas sea fiel al plan aprobado.

## Reglas

- **NO escribas código ni edites archivos** en este paso. La implementación la hará el `/goal` que forjes, tras la aprobación del usuario.
- Si necesitas una decisión del usuario para continuar, **DETENTE y pregunta** — no fijes el plan sobre un supuesto.
- Cuando termines el plan, **preséntalo para aprobación**. Si el usuario lo aprueba → forja el goal (arriba). Si quiere ajustes → itéralo antes de forjar. No forjes un goal sobre un plan que aún no aprobó.
