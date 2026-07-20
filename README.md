# optimization-skills

Skills para [Claude Code](https://docs.claude.com/en/docs/claude-code) que auditan, planean y ponen en marcha la mejora de un proyecto. Pensados para usarse en secuencia: `audit` levanta los hallazgos, `plan-fixes` los convierte en un plan por fases, y `goalsmith` forja el `/goal` que lo ejecuta en jornada autónoma. Ninguno de los tres toca el código: el último emite el comando, no lo corre.

El norte de los tres es el **punto óptimo, no el máximo**: más velocidad, mejores features y minimalismo, menos peso y complejidad. Penalizan la sobre-ingeniería.

## Skills

| Skill | Qué hace | Cuándo usarlo |
|---|---|---|
| [`audit`](audit/SKILL.md) | Audita un proyecto como ingeniero senior crítico a propósito. Explora y verifica en el código antes de opinar; pregunta ante ambigüedad. Evalúa 9 ejes (UI, UX, DX, Datos, Seguridad, Resiliencia, Optimización, Verificación, Operacional) con severidad y anclas `archivo:línea`. Solo audita y propone — no cambia código. | Auditar, revisar a fondo, o evaluar la salud de un codebase. |
| [`plan-fixes`](plan-fixes/SKILL.md) | Diseña un plan por fases para atacar los hallazgos de una auditoría previa. Primero pregunta las decisiones de alcance que cambian el plan de raíz y se detiene a esperar respuesta. Cada fase es entregable por sí sola, ordenada por riesgo→dependencia, con métrica y esfuerzo. No implementa todavía. | Tras `audit`, o para planear cómo atacar deuda técnica sin codear aún. |
| [`goalsmith`](goalsmith/SKILL.md) | Convierte un objetivo crudo en un comando `/goal` bien formado que sostiene jornadas largas: criterio verificable, backlog descompuesto, política de decisión autónoma, política de bloqueo y backstop. Emite el texto listo para pegar; no ejecuta el goal. | Tras aprobar un plan, o para cualquier tarea autónoma de larga duración. |

## Flujo típico

```
/audit        → reporte de hallazgos por eje, con severidad y tabla de prioridades
                (opcional: lo guarda en audit-report.md como entregable)
/plan-fixes   → lee audit-report.md si existe → plan por fases
                (quick-wins, condicionales, secuencia recomendada)
/goalsmith    → tras aprobar el plan, forja el /goal que lo ejecuta
                (fases → backlog, métricas → criterio de hecho, non-goals → scope)
```

El artefacto `audit-report.md` conecta los dos primeros: hace que el plan parta del reporte completo aunque el contexto del chat se haya resumido entremedio, en vez de depender de que los hallazgos sigan "en memoria". El plan aprobado, a su vez, es el insumo de `goalsmith` — trae casi todo lo que su entrevista extraería, así que salta preguntas y va directo a forjar.

Cada uno se detiene a preguntar cuando una decisión cambia el resultado, en vez de avanzar sobre suposiciones.

## Instalación

Los skills viven como carpetas bajo `~/.claude/skills/`. Para instalarlos:

```bash
git clone https://github.com/EngellBG/optimization-skills.git
cp -R optimization-skills/audit       ~/.claude/skills/
cp -R optimization-skills/plan-fixes  ~/.claude/skills/
cp -R optimization-skills/goalsmith   ~/.claude/skills/
```

Reinicia Claude Code (o abre una sesión nueva) y quedan disponibles como `/audit`, `/plan-fixes` y `/goalsmith`.

> Cada skill es un `SKILL.md` con frontmatter (`name`, `description`); `goalsmith` suma un `templates/` con el esqueleto del goal. No tienen dependencias ni scripts — solo instrucciones que Claude Code carga cuando el contexto coincide con la descripción.

## Licencia

[MIT](LICENSE)
