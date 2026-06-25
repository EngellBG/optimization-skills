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

## Reglas

- **NO escribas código ni edites archivos** en este paso. La implementación es un paso aparte que el usuario aprobará después de revisar el plan.
- Si necesitas una decisión del usuario para continuar, **DETENTE y pregunta** — no fijes el plan sobre un supuesto.
- Cuando termines el plan, **pregunta por dónde quiere arrancar**.
