# Plantilla de comando /goal

Rellena los campos entre <...>. Emite el bloque SIN espacio inicial, en un mensaje que empiece exactamente con `/goal`.

```
/goal <misión, una frase>
BACKLOG: <N unidades, o un comando que las lista>. Una unidad por iteración. Commit por unidad. Estado en <archivo>.
HECHO CUANDO: `<comando>` da <resultado exacto>. No declares hecho sin correr ese comando y ver ese resultado.
DECISIONES: ante varias opciones, evalúa cada una contra el criterio, prueba la más prometedora y elige la que más acerque al objetivo; registra la elección en <archivo>. No pares a preguntar por decisiones reversibles. Escala solo si es irreversible/destructivo, cambia el alcance o toca un non-goal.
SCOPE: <archivos/áreas>. NO TOCAR: <non-goals>.
SI BLOQUEADO: marca [BLOCKED: razón] en <archivo> y salta al siguiente. El criterio de éxito ignora los BLOCKED.
BACKSTOP: si <tope de iteraciones/budget> o la intención es dudosa → resume el progreso y pregunta. No marques falso done.
```

## Checklist inicial para disco (acompaña al goal)

Archivo: `PROGRESS.md` (o el que indique el SCOPE). Persiste el backlog entre iteraciones.

```
# Progreso — <misión>

## Pendiente
- [ ] unidad 1
- [ ] unidad 2
- [ ] unidad N

## Hecho
(se llena con commits)

## Decisiones
(cada bifurcación resuelta: opción elegida + por qué acerca al criterio)

## Bloqueado
(se llena con [BLOCKED: razón])
```

## Ejemplo lleno

```
/goal lleva la suite de tests de api/ a verde
BACKLOG: cada archivo en api/__tests__/ que falla. Corre `npm test -- --listTests` para la lista. Una unidad (archivo) por iteración. Commit por archivo. Estado en PROGRESS.md.
HECHO CUANDO: `npm test` da exit 0 con 0 failing y 0 skipped. No declares hecho sin correrlo.
DECISIONES: ante varias formas de arreglar un test (mockear, refactor, ajustar fixture), elige la que pase el test sin romper otros y que más acerque a verde; regístrala en PROGRESS.md. No preguntes por eso. Escala solo si arreglar exige cambiar un contrato de API público o borrar datos.
SCOPE: api/ y sus tests. NO TOCAR: web/, infra/, migraciones de DB.
SI BLOQUEADO: marca [BLOCKED: razón] en PROGRESS.md y salta. El criterio ignora los BLOCKED.
BACKSTOP: tras 25 iteraciones sin reducir el conteo de fallos, o si un test exige decisión de producto → resume y pregunta. No marques falso done.
```
