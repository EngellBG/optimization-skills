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
5. **Reportar** según las reglas de salida.

Para repos grandes, paraleliza la exploración con subagentes `Explore` (uno por capa/eje), pero el juicio final y el reporte los consolidas tú.

## Ejes a evaluar

Omite el que no aplique — y di que lo omites.

1. **UI** — jerarquía visual, consistencia, accesibilidad real (aria, navegación por teclado, foco, contraste).
2. **UX** — flujos, pérdida de trabajo, feedback de errores, casos límite, estados vacíos/carga.
3. **DX** — estructura, código muerto, dependencias (sin usar / desactualizadas / pesadas), docs vs realidad, build reproducible.
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

## Lo que NO debe hacer este skill

- No editar código (solo auditar y proponer).
- No inventar hallazgos: cada uno debe estar anclado a código verificado.
- No sobre-ingeniería en las recomendaciones — propón lo mínimo que resuelve.
- No avanzar sobre supuestos no confirmados cuando la decisión cambia el resultado.
