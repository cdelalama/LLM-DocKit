# Analisis Comparativo: LLM-DocKit vs Code Factory (Ryan Carson)

> Archived: 2026-06-18
> Status: lineage / inspiration source, not an implementation proposal.
> Kept for the risk-tier, SHA-discipline, remediation-loop, and
> evidence-over-auto-report ideas it captured. Live productization belongs in
> ForgeOS where relevant, or in a future LLM-DocKit DF for scaffold-level
> validator changes. Do not treat this comparison as accepted roadmap.

Fecha: 2026-02-19
Autor: Claude Opus 4.6
Contexto: Analisis solicitado para evaluar si el patron "Code Factory" inspira cambios arquitectonicos en LLM-DocKit.

---

## 1. Que es cada cosa

### LLM-DocKit (lo nuestro)

Un **scaffold de documentacion** que resuelve el problema de memoria y continuidad entre sesiones de LLMs. Su nucleo es:

- **HANDOFF.md**: estado actual del proyecto (fuente unica de verdad).
- **HISTORY.md**: log cronologico append-only.
- **DECISIONS.md**: razonamiento de decisiones arquitectonicas.
- **LLM_START_HERE.md**: contrato/constitucion que todo LLM debe leer.
- **Reglas no negociables**: actualizar docs cada sesion, respetar zonas protegidas, seguir versionado semantico.

Su propuesta V2 (CE) anade: modos operativos (base/ce/emergency), manifests de sesion, validacion CI por diffs reales, biblioteca de soluciones reutilizables y politica de contexto.

**Foco**: gobernanza de conocimiento y continuidad entre sesiones LLM. Es agnóstico del pipeline CI/CD concreto.

### Code Factory (Ryan Carson)

Un **patron de control-plane para CI/CD** donde agentes de IA escriben Y revisan el 100% del codigo. Su nucleo es:

- **Contrato de riesgo**: JSON que define tiers de riesgo por path y checks requeridos por tier.
- **Risk policy gate**: preflight que bloquea CI costoso si la politica no se cumple.
- **SHA discipline**: solo acepta estado de review que coincida con el HEAD actual del PR.
- **Rerun deduplication**: un unico writer canonico para evitar race conditions en comentarios bot.
- **Remediation loop**: agente de codigo que lee findings del reviewer, parchea, pushea, y dispara re-review automatica.
- **Browser evidence**: pruebas de UI como artefactos de primera clase en CI.
- **Harness gap loop**: incidentes en produccion se convierten en casos de test permanentes.

**Foco**: automatizacion del ciclo write-review-merge con agentes, con guardrails deterministas y evidencia verificable por maquina.

---

## 2. Donde se solapan

| Concepto | LLM-DocKit | Code Factory |
|---|---|---|
| Contrato machine-readable | LLM_START_HERE.md (markdown, para LLMs) + V2 CONTRACT_VERSION | risk-tier JSON (para CI) |
| Preflight gate | V2 preflight (manifest + plan_ref) | risk-policy-gate (tier + checks) |
| Evidencia real vs auto-reporte | V2 P0: "CI = evidencia, manifest = intencion" | Core: SHA discipline + checks reales |
| Modos operativos | V2: base/ce/base_emergency | Implicit: high-risk/low-risk tiers |
| Trazabilidad | work_unit_id + session manifests | SHA-per-check + rerun markers |
| Knowledge reuse | V2 solutions library con lifecycle | harness-gap loop (incidentes -> tests) |

**Observacion clave**: ambos sistemas convergen en la misma intuicion fundamental: **no confies en auto-reporte, valida por evidencia**. LLM-DocKit lo dice en su V2 P0 ("manifest = intencion, CI = evidencia"). Code Factory lo implementa con SHA discipline.

---

## 3. Donde divergen (y por que importa)

### 3.1 Scope del agente

- **LLM-DocKit** asume que el humano controla el loop: decide que hacer, el LLM ejecuta, el humano revisa.
- **Code Factory** asume que **agentes controlan el loop completo**: un agente escribe, otro revisa, un tercero remedia. El humano es supervisor, no operador.

**Implicacion**: LLM-DocKit esta disenado para el presente (humano + LLM). Code Factory esta disenado para un futuro cercano (agente + agente + humano como auditor).

### 3.2 Granularidad del riesgo

- **LLM-DocKit** tiene "Do Not Touch zones" (binario: tocas o no tocas) y modos (base/ce/emergency).
- **Code Factory** tiene **risk tiers por path** con checks granulares por tier.

**Implicacion**: Code Factory permite politicas mas finas. Un cambio en `db/schema.ts` exige 4 checks; un cambio en `README.md` exige 2. LLM-DocKit trata todo con el mismo nivel de rigor (o lo ignora con `base`).

### 3.3 Ciclo de remediacion automatica

- **LLM-DocKit** no tiene concepto de remediacion automatica. Si un review encuentra problemas, se documentan en REVIEWS.md y se resuelven en la siguiente sesion (o la misma, manualmente).
- **Code Factory** tiene un **loop cerrado**: review -> findings -> agente remedia -> push -> re-review -> merge. Sin intervencion humana si todo pasa.

**Implicacion**: esto es la diferencia mas grande. Code Factory puede cerrar un PR completo sin que un humano toque nada. LLM-DocKit requiere intervencion humana en cada paso.

### 3.4 Estado del review como first-class citizen

- **LLM-DocKit** trata reviews como documentacion opcional (REVIEWS.md).
- **Code Factory** trata el estado del review como un **gate bloqueante** con SHA pinning. No te puedes saltar un review desactualizado.

### 3.5 Browser evidence

- **LLM-DocKit** no tiene concepto de evidencia visual/funcional.
- **Code Factory** requiere **capturas y aserciones de UI** como artefactos de CI para cambios de interfaz.

---

## 4. Que me inspira para LLM-DocKit

### 4.1 Risk tiers por path (ALTA INSPIRACION)

Esto es directamente aplicable. En lugar de "Do Not Touch" (binario), LLM-DocKit podria definir:

```yaml
# En LLM_START_HERE.md o un nuevo RISK_POLICY.yaml
risk_tiers:
  critical:
    paths: ["db/migrations/**", "auth/**", "payments/**"]
    requires: [plan, review, tests, human_approval]
  standard:
    paths: ["src/**", "lib/**"]
    requires: [plan, review, tests]
  low:
    paths: ["docs/**", "README.md", "*.config.*"]
    requires: [review]
```

**Ventaja**: permite que el LLM auto-detecte el nivel de rigor necesario sin preguntarle al humano. Hoy, la decision base/ce depende de heuristicas vagas (">5 archivos"). Con risk tiers por path, es determinista.

**Como integrarlo**: extender LLM_START_HERE.md con una seccion de risk policy. El manifest de sesion V2 declararia el tier detectado. CI validaria que los checks del tier se cumplieron.

### 4.2 SHA discipline para reviews (ALTA INSPIRACION)

LLM-DocKit V2 ya tiene work_unit_id y session manifests, pero no tiene el concepto de "este review es valido solo para este SHA". Si multiples sesiones trabajan en la misma rama, un review de la sesion 1 no deberia considerarse valido despues de la sesion 2.

**Como integrarlo**: cada entrada en REVIEWS.md deberia incluir el commit SHA que fue revisado. CI deberia validar que el ultimo review referencia el HEAD actual del PR.

### 4.3 Remediation loop (INSPIRACION MEDIA - futuro)

Hoy esto es prematuro para LLM-DocKit porque asume agentes autonomos. Pero el patron es claro y vale documentarlo como norte:

1. Review agent encuentra findings.
2. Coding agent lee findings + contexto.
3. Coding agent parchea y pushea.
4. Se dispara re-review automatica.
5. Si pasa, merge. Si no, loop (con limite).

**Como prepararse**: la estructura de REVIEWS.md podria evolucionar para tener findings en formato machine-readable (no solo prosa). Esto permitiria que un agente futuro los consuma sin parsing ambiguo.

### 4.4 Deduplicacion y writer canonico (INSPIRACION BAJA pero practica)

Si LLM-DocKit llega a tener multiples agentes operando en paralelo (ya contemplado en V2 seccion 6), el patron de "un unico writer canonico con deduplicacion por marker" evita race conditions en HANDOFF.md.

**Como integrarlo**: ya esta parcialmente resuelto por el modelo de "ultimo merge gana" de V2. Pero si se automatizan mas pasos, un lockfile temporal o un marker de SHA en HANDOFF.md evitaria conflictos.

### 4.5 Contrato como JSON/YAML machine-readable (INSPIRACION ALTA)

LLM-DocKit usa markdown para todo. Esto es bueno para legibilidad humana y LLM, pero malo para CI. Code Factory usa JSON para el contrato de riesgo, lo que permite validacion determinista por scripts.

**Como integrarlo**: mantener markdown como formato primario (es la fortaleza de DocKit), pero agregar un archivo de contrato machine-readable (YAML preferible a JSON por legibilidad):

```yaml
# docs/llm/CONTRACT.yaml
version: "2.1"
risk_tiers: { ... }
merge_policy: { ... }
context_limits:
  handoff_max_lines: 200
  history_shard: monthly
required_artifacts:
  ce: [manifest, plan, review, handoff_update, history_entry]
  base: [handoff_update, history_entry]
```

CI validaria contra este YAML. Los docs en markdown seguirian siendo la referencia para humanos y LLMs.

### 4.6 Harness gap loop (INSPIRACION MEDIA)

El concepto de "incidente en produccion -> caso de test permanente" encaja bien con la solutions library de V2. Cada incidente podria generar:

1. Una entrada en solutions con el patron de fallo y la correccion.
2. Un test case en el harness del proyecto.
3. Un link en DECISIONS.md si cambio la arquitectura.

**Como integrarlo**: agregar un template `INCIDENT_TO_SOLUTION.md` en la solutions library que guie la conversion de incidentes en conocimiento reutilizable.

---

## 5. Que NO haria (y por que)

### 5.1 NO adoptaria browser evidence como parte del scaffold

LLM-DocKit es un scaffold de documentacion agnóstico del stack tecnologico. La browser evidence es especifica de proyectos web con UI. Seria sobreingenieria incluirlo en el scaffold base.

**Alternativa**: documentar el patron en una guia de integracion (`docs/integrations/BROWSER_EVIDENCE.md`) para proyectos que lo necesiten.

### 5.2 NO implementaria el remediation loop ahora

El ecosistema de agentes autonomos no esta lo suficientemente maduro para que esto sea fiable en la mayoria de equipos. El riesgo de un agente que parchea y pushea sin supervision es alto.

**Alternativa**: mantenerlo como norte en la roadmap de V3 o posterior. Cuando los agentes de review (Greptile, CodeRabbit, etc.) y los de codigo (Codex, Claude) sean mas fiables, el patron sera plug-and-play si la estructura de REVIEWS.md ya soporta findings machine-readable.

### 5.3 NO cambiaria el modelo mental de "sesion"

Code Factory opera en PRs. LLM-DocKit opera en sesiones. Son modelos complementarios, no excluyentes. Una sesion puede producir uno o mas PRs. El modelo de sesion es mas natural para la interaccion humano-LLM y permite documentar trabajo que no resulta en codigo (investigacion, decisiones, planificacion).

---

## 6. Arquitectura propuesta (si decidimos evolucionar)

```
LLM-DocKit v2 (actual)          LLM-DocKit v2.5 (inspirado)
========================         ============================

LLM_START_HERE.md          -->   LLM_START_HERE.md (compacto)
                                 + docs/llm/CONTRACT.yaml (machine-readable)
                                 + docs/llm/RISK_POLICY.yaml (tiers por path)

HANDOFF.md                 -->   HANDOFF.md (sin cambios)

HISTORY.md                 -->   history/YYYY-MM.md (ya en V2)

DECISIONS.md               -->   DECISIONS.md (sin cambios)

REVIEWS.md                 -->   reviews/YYYY-MM.md (ya en V2)
                                 + SHA pinning por review
                                 + findings en formato estructurado

SESSION manifests          -->   SESSION manifests (ya en V2)
                                 + risk_tier detectado automaticamente

solutions library          -->   solutions library (ya en V2)
                                 + template INCIDENT_TO_SOLUTION.md
                                 + harness gap tracking

CI validation              -->   CI validation (ya en V2)
                                 + validacion contra CONTRACT.yaml
                                 + risk tier enforcement
                                 + SHA freshness check en reviews

Do Not Touch zones         -->   Risk tiers (critical/standard/low)
                                 + "Do Not Touch" como caso extremo de critical
```

---

## 7. Resumen ejecutivo

| Dimension | LLM-DocKit hoy | Code Factory | Mi recomendacion |
|---|---|---|---|
| Foco | Documentacion + continuidad | Pipeline CI/CD autonomo | Mantener foco en documentacion, agregar hooks para CI |
| Agente principal | LLM asistido por humano | Agentes autonomos en loop | Preparar estructura para autonomia futura sin forzarla hoy |
| Contrato | Markdown para humanos/LLMs | JSON para CI | Dual: YAML para CI + Markdown para humanos |
| Riesgo | Binario (touch/no-touch) | Tiers por path con checks graduales | Adoptar risk tiers (alta prioridad) |
| Reviews | Documentacion opcional | Gate bloqueante con SHA pinning | Agregar SHA pinning (alta prioridad) |
| Remediacion | Manual | Loop automatico agente-agente | Preparar formato machine-readable, implementar despues |
| Evidencia visual | No existe | Browser evidence en CI | No incluir en scaffold base, documentar como integracion |
| Incidentes | No existe | Harness gap loop | Adoptar via solutions library + template |

---

## 8. Conclusion

Ryan Carson esta construyendo el **plano de ejecucion** (como hacer que agentes escriban y revisen codigo de forma segura). Nosotros estamos construyendo el **plano de conocimiento** (como hacer que los agentes no pierdan contexto ni rompan cosas entre sesiones).

Son capas complementarias, no competidoras:

```
Capa 4: Remediation loop (agente corrige findings) ......... Code Factory
Capa 3: Review gate (agente valida PR) ..................... Code Factory
Capa 2: CI/CD pipeline (risk tiers, SHA discipline) ........ Code Factory
Capa 1: Gobernanza de conocimiento (handoff, history) ...... LLM-DocKit
Capa 0: Proyecto (codigo fuente, tests, config) ............ Ambos
```

LLM-DocKit es la Capa 1. Code Factory es las Capas 2-4. La inspiracion mas valiosa es hacer que la Capa 1 sea **consumible por las Capas 2-4**: contratos en YAML, risk tiers por path, SHA pinning en reviews, y findings estructurados.

No necesitamos cambiar la arquitectura. Necesitamos **extender la interfaz** de nuestros artefactos para que sean machine-readable ademas de human-readable.

Eso es lo que haria como v2.5 antes de intentar construir las capas superiores.
