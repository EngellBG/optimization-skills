# optimization-skills

Skills para [Claude Code](https://docs.claude.com/en/docs/claude-code) que auditan y planean la mejora de un proyecto sin tocar el código. Pensados para usarse en secuencia: primero `audit` levanta los hallazgos, luego `plan-fixes` los convierte en un plan por fases.

El norte de ambos es el **punto óptimo, no el máximo**: más velocidad, mejores features y minimalismo, menos peso y complejidad. Penalizan la sobre-ingeniería.

## Skills

| Skill | Qué hace | Cuándo usarlo |
|---|---|---|
| [`audit`](audit/SKILL.md) | Audita un proyecto como ingeniero senior crítico a propósito. Explora y verifica en el código antes de opinar; pregunta ante ambigüedad. Evalúa 9 ejes (UI, UX, DX, Datos, Seguridad, Resiliencia, Optimización, Verificación, Operacional) con severidad y anclas `archivo:línea`. Solo audita y propone — no cambia código. | Auditar, revisar a fondo, o evaluar la salud de un codebase. |
| [`plan-fixes`](plan-fixes/SKILL.md) | Diseña un plan por fases para atacar los hallazgos de una auditoría previa. Primero pregunta las decisiones de alcance que cambian el plan de raíz y se detiene a esperar respuesta. Cada fase es entregable por sí sola, ordenada por riesgo→dependencia, con métrica y esfuerzo. No implementa todavía. | Tras `audit`, o para planear cómo atacar deuda técnica sin codear aún. |

## Flujo típico

```
/audit        → reporte de hallazgos por eje, con severidad y tabla de prioridades
/plan-fixes   → plan por fases (quick-wins, condicionales, secuencia recomendada)
```

Cada uno se detiene a preguntar cuando una decisión cambia el resultado, en vez de avanzar sobre suposiciones.

## Instalación

Los skills viven como carpetas bajo `~/.claude/skills/`. Para instalarlos:

```bash
git clone https://github.com/EngellBG/optimization-skills.git
cp -R optimization-skills/audit       ~/.claude/skills/
cp -R optimization-skills/plan-fixes  ~/.claude/skills/
```

Reinicia Claude Code (o abre una sesión nueva) y quedan disponibles como `/audit` y `/plan-fixes`.

> Cada skill es un único `SKILL.md` con frontmatter (`name`, `description`). No tienen dependencias ni scripts — solo instrucciones que Claude Code carga cuando el contexto coincide con la descripción.

## Licencia

[MIT](LICENSE)
