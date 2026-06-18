# RFC Consolidado: LLM-DocKit V2 + Compound Engineering

> Archived: 2026-06-18
> Status: hybrid lineage.
> Parts are implemented in LLM-DocKit 4.x (SessionStart preflight,
> Stop-hook postflight, CI/pre-commit validation, Trace Protocol). Parts are
> superseded by ForgeOS v5 concepts (`WorkEpisode` over session manifests,
> `AuthorityEngine` over authority/risk policy, future `ProtocolEngine` over
> review/consensus execution). Remaining useful ideas, such as risk tiers,
> SHA-pinned reviews, and machine-readable contracts, should be reconsidered
> through a new DF or ForgeOS ticket, not implemented directly from this draft.

Fecha: 2026-02-07
Estado: Ready for Pilot
Objetivo: Definir un contrato operativo ejecutable, con bajo overhead y validable por CI.

## 1. Contexto y alcance

Este RFC consolida decisiones tomadas entre multiples sesiones y LLMs sobre como integrar LLM-DocKit con Compound Engineering (CE) sin fusionar proyectos.

Alcance:

1. Reglas operativas para trabajo diario (`base`, `ce`, `base_emergency`).
2. Contrato de artefactos y validaciones CI.
3. Estrategia de contexto, paralelismo, descubrimiento de solutions y governance humana.
4. Condiciones de piloto, rollback y versionado del contrato.

No alcance:

1. Implementacion de logica de negocio.
2. Optimizaciones avanzadas antes de tener datos de piloto.

## 2. Decision principal

Se adopta Opcion C: **separados + integrados por contrato**.

1. `LLM-DocKit` queda como capa estable de gobernanza/memoria.
2. `CE` queda como capa de ejecucion (`plan -> work -> review -> compound`).
3. Integracion por artefactos y evidencia de diffs (no por auto-reporte).

Razon:

1. Evita deuda de mantenimiento de una fusion dura.
2. Permite evolucionar CE sin romper el scaffold base.
3. Hace auditable la colaboracion multi-LLM.

## 3. Prioridades de decision (lo mas importante)

## P0 (bloqueantes, no negociables)

1. **Manifest = intencion, CI = evidencia.**
   - Por que: si CI confia en booleanos auto-reportados, el guardrail es teatro.
2. **Preflight + Postflight + CI (no solo PR final).**
   - Por que: detectar fallos antes de escribir codigo evita retrabajo.
3. **Contrato versionado (`dockit_contract_version`).**
   - Por que: sin versionado, reglas nuevas rompen repos viejos sin claridad.
4. **Politica de context window.**
   - Por que: sin poda/compactacion, el framework se sabotea por exceso de contexto.
5. **`work_unit_id` obligatorio por sesion.**
   - Por que: sin unidad de trabajo trazable, se mezcla contexto y cae la auditabilidad.

## P1 (muy importantes)

1. `base` vs `ce` con criterio explicito y default `ce` en duda.
2. Modo emergencia con friccion minima y escalado si se abusa.
3. Discovery de `solutions` con indice autogenerado.
4. Lifecycle de `solutions`: `candidate -> canonical -> superseded`.
5. Soporte a sesiones paralelas sin lock complejo.

## P2 (soporte de adopcion)

1. Bootstrap (`init`) para repos existentes.
2. Rollback (`remove_v2.sh`) para desinstalar framework sin dañar negocio.
3. Checklist humano corto para evitar microgestion o abandono.
4. Graceful degradation para modelos menos capaces.

## 4. Contrato operativo v2.1

## 4.1 Version de contrato

Archivo canonico:

- `docs/llm/CONTRACT_VERSION`

Valor inicial:

- `2.1`

Cada manifest declara:

- `dockit_contract_version: 2.1`

Regla:

1. CI valida manifest contra contrato activo.
2. Cambios incompatibles requieren bump major y nota de migracion.

## 4.2 Modos

1. `base`: flujo ligero.
2. `ce`: flujo completo.
3. `base_emergency`: bypass temporal por incidente.

Criterio default para seleccionar modo:

1. `ce` si toca >5 archivos.
2. `ce` si introduce logica nueva.
3. `ce` si toca auth/pagos/migraciones/esquema/API publica.
4. `ce` si es incidente de produccion.
5. `base` solo para cambios triviales (docs/typos/config sin logica).
6. En duda: `ce`.

## 4.3 Manifest de sesion (ligero)

Ruta:

- `docs/llm/SESSIONS/YYYY-MM/session-<session_id>.md`

Frontmatter minimo:

```yaml
dockit_contract_version: 2.1
session_id: 2026-02-07-a1
mode: ce # base|ce|base_emergency
work_unit_id: FEAT-123
related_units: [] # opcional
plan_ref: docs/plans/2026-02-07-feat-123.md
status: in_progress # in_progress|done|blocked
incident_reason: "" # requerido si mode=base_emergency
regularize_by: next_session # default en emergencia
consulted_solutions: [] # opcional
```

Reglas:

1. El manifest no contiene booleanos de cumplimiento (`handoff_updated`, etc.).
2. Cumplimiento lo decide CI por diffs reales.
3. Owner del manifest: LLM de la sesion.
4. Fallback humano: `scripts/new_session.sh`.

## 5. Artefactos y rutas

| Fase | Artefacto | Ruta | Regla |
|---|---|---|---|
| plan | plan de trabajo | `docs/plans/*.md` | obligatorio en `ce` antes de `work` |
| work | resumen por sesion | `docs/llm/SESSIONS/...` | obligatorio siempre |
| work | estado global | `docs/llm/HANDOFF.md` | actualizar en PR de la sesion |
| work | historial mensual | `docs/llm/history/YYYY-MM.md` | append por sesion |
| review | resumen review | `docs/llm/reviews/YYYY-MM.md` | obligatorio en `ce` |
| review | findings | `todos/*-pending-*.md` | si hay hallazgos |
| compound | solucion reusable | `docs/solutions/<domain>/<slug>.md` | cuando aplica |

## 6. Paralelismo (sesiones simultaneas)

Modelo:

1. Cada rama/worktree escribe su propio `session-*.md`.
2. Cada PR actualiza `HANDOFF.md` global junto con su session summary.
3. Conflictos en `HANDOFF` se resuelven por flujo normal de Git.
4. Regla practica: ultimo merge gana + revision manual si colision semantica.

Razon:

1. Evita lockeo central.
2. Mantiene trazabilidad por sesion.
3. Usa un mecanismo que el equipo ya conoce (merge conflict).

## 7. Preflight, postflight y CI

## 7.1 Preflight (inicio)

Si `mode=ce`:

1. Debe existir `plan_ref`.
2. Debe existir manifest.
3. Debe existir `work_unit_id`.
4. Debe cargarse lectura minima de contexto.

Si falla preflight:

1. No iniciar cambios de codigo.
2. Crear artefactos minimos primero.

## 7.2 Postflight (cierre de sesion)

1. Actualizar manifest (`status`).
2. Actualizar `HANDOFF.md`.
3. Append en `history/YYYY-MM.md`.
4. En `ce`, actualizar review y/o todos.
5. Si hubo aprendizaje reusable, crear/actualizar `solutions`.

## 7.3 CI (evidencia por diff)

Script:

- `scripts/validate_compound_workflow.sh`

Validaciones:

1. Manifest nuevo/modificado => diff en `HANDOFF.md` y `history/YYYY-MM.md`.
2. `mode=ce` => diff en `reviews/YYYY-MM.md` o `todos/`.
3. Si se agrega `docs/solutions/*` => actualizar `docs/solutions/INDEX.md`.
4. `mode=base_emergency` sin regularizacion en 2 sesiones consecutivas => fail.
5. `dockit_contract_version` incompatible => fail.

Severidad:

1. Piloto: advisory por defecto, strict en checks P0.
2. Post-piloto: strict para reglas acordadas.

## 8. Politica de contexto (anti-sobreingenieria)

## 8.1 Limites

1. `HANDOFF.md`: warning >100 lineas, hard fail >200.
2. `reviews/YYYY-MM.md`: solo resumen + links.
3. `history/YYYY-MM.md`: shard mensual.

## 8.2 Compactacion

1. Cierre mensual: `docs/llm/SUMMARY_YYYY-MM.md`.
2. Cierre trimestral: consolidar patrones en `DECISIONS.md` y canonical solutions.

## 8.3 Lectura minima de arranque

1. `LLM_START_HERE.md` (version compacta, 1 pagina).
2. `docs/llm/HANDOFF.md`.
3. Ultimo `session-*.md`.
4. `docs/solutions/INDEX.md` (top prefiltrado).

Referencia extendida:

- `docs/integrations/COMPOUND_ENGINEERING.md`

## 9. Solutions: descubrimiento y lifecycle

## 9.1 Descubrimiento

Indice autogenerado:

- `docs/solutions/INDEX.md`

Generator:

- `scripts/index_solutions.sh`

Contenido por entrada:

1. `slug`
2. `one_liner`
3. `tags`
4. `domain`
5. `status`
6. `updated_at`

Matching en preflight:

1. Script prefiltra top 10 por `domain/tags/work_unit/keywords`.
2. LLM reranquea ese top 10 y decide cuales consultar.

Razon:

1. Bash solo no tiene matching semantico suficiente.
2. LLM sobre todo el corpus consume demasiado contexto.
3. Hibrido da mejor costo/recall.

## 9.2 Lifecycle

Estados:

1. `candidate`
2. `canonical`
3. `superseded`

Promocion automatica a `promotion_candidate` cuando:

1. `consulted_count >= 2`
2. Referencias en `work_unit_id` distintos
3. Ventana de 30 dias

Decision final:

1. Humano aprueba o rechaza promocion.

## 10. Rol humano (explicito)

Archivo:

- `docs/HUMAN_CHECKLIST.md`

Checklist (10 lineas max):

1. Validar si `mode` fue correcto.
2. Validar abuso de `base_emergency`.
3. Revisar findings P1/P2 relevantes.
4. Aprobar/rechazar promociones a `canonical`.
5. Confirmar version de contrato en cambios de framework.

## 11. Bootstrap, instalacion y rollback

## 11.1 Bootstrap

Script:

- `scripts/init_v2.sh`

Acciones:

1. Crea estructura minima V2.
2. Crea `docs/llm/CONTRACT_VERSION`.
3. Activa CI en advisory hasta completar init.

## 11.2 Graceful degradation

Script:

- `scripts/new_session.sh --mode=ce --work_unit=... --plan_ref=...`

Uso:

1. Para humanos.
2. Para modelos que no siguen reglas complejas consistentemente.

## 11.3 Rollback

Script:

- `scripts/remove_v2.sh`

Regla:

1. Remueve scaffolding V2/CI de framework.
2. No toca codigo de negocio.
3. No elimina historico existente sin confirmacion explicita.

## 12. Testing del propio framework

Casos minimos:

1. `pass_ce_complete`
2. `fail_missing_handoff`
3. `pass_base_emergency`
4. `fail_no_manifest`
5. `fail_contract_version_mismatch`
6. `fail_emergency_not_regularized_2_sessions`

Razon:

1. Guardrail sin pruebas pierde confianza en el primer falso positivo.

## 13. Piloto (reglas de ejecucion)

Duracion:

- 2 semanas

Scope:

1. 2 repos
2. 6-10 sesiones
3. mix de tareas chicas y medianas

Metricas obligatorias del piloto:

1. `Review Coverage`
2. `Handoff Completeness`

Metricas opcionales:

1. Reopen Rate
2. Cycle Time
3. Reuse de solutions

Regla de congelamiento:

1. No cambiar contrato durante piloto.
2. Excepcion: bug critico del guardrail.

## 14. Decision Lock (para no perder contexto)

Estado de decisiones cerradas:

1. Separados + contrato: **LOCKED**
2. Manifest intencion / CI evidencia: **LOCKED**
3. Sin booleanos auto-reportados: **LOCKED**
4. Preflight + postflight + CI: **LOCKED**
5. `work_unit_id` obligatorio: **LOCKED**
6. Modo emergencia simple + escalado 2 sesiones: **LOCKED**
7. Context window con poda y shards: **LOCKED**
8. `LLM_START_HERE` compacto + referencia extendida: **LOCKED**
9. Discovery de solutions con indice autogenerado: **LOCKED**
10. Matching hibrido (prefiltro script + reranking LLM): **LOCKED**
11. Lifecycle candidate/canonical/superseded: **LOCKED**
12. Promocion por reuse (>=2 work_units, 30 dias): **LOCKED**
13. Contract versioning: **LOCKED**
14. Bootstrap `init_v2.sh`: **LOCKED**
15. Rollback `remove_v2.sh`: **LOCKED**
16. Human checklist explicito: **LOCKED**
17. Test suite del framework: **LOCKED**
18. Freeze de reglas en piloto: **LOCKED**

## 15. Que es mas importante

Orden de importancia para ejecutar sin sobreingenieria:

1. P0: evidencia real por CI, pre/postflight, versionado, contexto, trazabilidad por work unit.
2. P1: discovery/lifecycle de knowledge y operacion de emergencia.
3. P2: tooling de adopcion, rollback y ergonomia.

Si hay conflicto entre velocidad y completitud documental:

1. Priorizar P0.
2. Mantener P1 minimo viable.
3. Diferir P2 hasta despues de piloto.

Este RFC queda como fuente canonica para la implementacion del piloto.
