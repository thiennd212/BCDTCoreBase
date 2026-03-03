<!--
SYNC IMPACT REPORT
==================
Version change: (none) → 1.0.0  [initial ratification]
Modified principles: N/A (first fill)
Added sections:
  - Core Principles (I–VI)
  - Technology Constraints
  - AI Workflow Protocol
  - Governance
Templates reviewed:
  - .specify/templates/plan-template.md  ✅ Constitution Check gate references these principles
  - .specify/templates/spec-template.md  ✅ No structural changes required (generic)
  - .specify/templates/tasks-template.md ✅ No structural changes required (generic)
Deferred TODOs: none
-->

# BCDT Constitution

## Core Principles

### I. Clean Architecture (NON-NEGOTIABLE)

Dependency flow is strictly one-directional and MUST NOT be violated:

- **Domain** (`BCDT.Domain`): zero external dependencies; contains Entities, Interfaces,
  Enums only.
- **Application** (`BCDT.Application`): depends on Domain only; contains Services, DTOs,
  Validators (FluentValidation).
- **Infrastructure** (`BCDT.Infrastructure`): implements Domain interfaces; contains
  AppDbContext, Repositories, External Services.
- **API** (`BCDT.Api`): calls Application only; contains Controllers, Middleware, Program.cs.

Any feature that requires a new dependency MUST be placed in the correct layer. Upward
dependencies (e.g., Infrastructure referencing API) are PROHIBITED without Manager approval
and a recorded decision in `memory/DECISIONS.md`.

### II. Security-First: RBAC + RLS (NON-NEGOTIABLE)

Every API endpoint MUST be protected:

- All controllers MUST carry `[Authorize]`; public endpoints are the explicit exception
  and require Manager approval.
- Row-Level Security (RLS) is enforced at the database level via `sp_SetSystemContext`.
  Session context MUST be set before any data access in request handlers and Hangfire jobs.
- Changing RLS policy, session context setup, Middleware order, or JWT configuration
  REQUIRES a MUST-ASK pause + decision recorded in `memory/DECISIONS.md`.
- FluentValidation validators MUST exist for every POST/PUT request DTO that crosses a
  system boundary (user input, external API).

### III. Result\<T\> Pattern — No Naked Exceptions

All Application-layer service methods MUST return `Result<T>`:

- Business logic errors use standard BCDT error codes:
  `NOT_FOUND`, `CONFLICT`, `VALIDATION_FAILED`, `UNAUTHORIZED`, `INVALID_FILE`.
- Exceptions MUST NOT be used for expected business conditions (not-found, invalid input,
  access denied). Use `Result.Failure(...)` instead.
- The API response contract is fixed:
  - Success: `{ "success": true, "data": { … } }`
  - Failure: `{ "success": false, "errors": [ … ] }`
- Deviating from this contract REQUIRES Manager approval.

### IV. Verify-Before-Done (NON-NEGOTIABLE)

No task is complete until verification passes:

- **Backend changes**: Build MUST pass (`dotnet build --no-restore`). Stop running
  `BCDT.Api` before building. Relevant Postman requests MUST return expected responses.
- **Frontend changes**: E2E test suite MUST pass (`npm run test:e2e`, BE at port 5080).
  Build MUST pass (`npm run build`).
- **API contract changes**: Postman collection MUST be updated and validated.
- Reporting "done" before verification is PROHIBITED. Failures MUST be reported with
  specific steps and outputs.

### V. Scope Discipline — MUST-ASK Before High-Risk Changes

Agents MUST pause and request explicit approval before touching any of the following:

- RLS / session context (Middleware, stored procedures, policy, 503 handling)
- Hangfire job logic that reads/writes RLS-protected tables
- Workbook flow contract (sync order, binding resolver, workbook-data structure)
- Dashboard / replica / AppReadOnlyDbContext strategy
- Production/deployment configuration (env vars, timeout, rate limit, CORS, JWT secrets)
- DB schema changes with production risk (dropping columns, altering types, removing FK)

All decisions in these areas MUST be recorded in `memory/DECISIONS.md` before implementation.
No wide-area refactoring ("improve while I'm here") is permitted without a separate task.

### VI. Standard Contracts — Table Prefix, Response, Error Codes

All persistent entities MUST use the `BCDT_` table prefix (currently 44+ tables).
No new table prefix is permitted without Manager approval and DB migration plan.

Error codes are a closed set unless extended via constitution amendment:
`NOT_FOUND` · `CONFLICT` · `VALIDATION_FAILED` · `UNAUTHORIZED` · `INVALID_FILE` ·
`SESSION_CONTEXT_FAILED` · `PAYLOAD_TOO_LARGE` · `RATE_LIMIT_EXCEEDED`

HTTP status codes follow REST convention. All responses MUST include the standard envelope.
Direct raw responses from controllers (bypassing `ApiResponse`) are PROHIBITED.

## Technology Constraints

These technology choices are **immutable** for the current MVP and post-MVP phase.
Any change requires a recorded decision and Manager approval.

| Layer | Technology | Version |
|---|---|---|
| Runtime | .NET | 8 |
| Web framework | ASP.NET Core | 8 |
| ORM | Entity Framework Core | 8 |
| Validation | FluentValidation | 11 |
| Background jobs | Hangfire | SQL Server storage |
| Cache | IDistributedCache (Redis / MemoryCache fallback) | — |
| Database | SQL Server | — |
| Frontend runtime | React | 19 |
| Frontend language | TypeScript | — |
| Frontend build | Vite | — |
| UI library | Ant Design | 6 |
| Data fetching | TanStack Query | — |
| Spreadsheet | Fortune Sheet | — |
| Auth | JWT + Refresh Token, BCrypt | — |

Dev server ports: BE `5080` (E2E), FE `5173`.
Swagger available at `https://localhost:7xxx/swagger`.

## AI Workflow Protocol

This section governs how AI agents (Claude Code as Manager, Cursor as Implementation
Agents) interact with the codebase.

**Manager (Claude Code) responsibilities:**
- Triage, plan, QA gate, risk assessment via SpecKit (`/speckit.*`) and APM (`/apm.*`).
- MUST NOT write production code directly; delegates to Implementation Agents via
  APM Task Assignment Prompts.
- Reviews Memory Logs and decides next task assignments.

**Implementation Agents (Cursor) responsibilities:**
- Execute specific tasks from Manager's Task Assignment Prompts.
- Follow Verify-Before-Done (Principle IV) before logging completion.
- MUST-ASK Manager before any Scope Discipline triggers (Principle V).
- After 3 failed debug attempts, MUST delegate via `/apm-8-delegate-debug`.

**Feature lifecycle (SpecKit → APM):**
1. Manager creates spec: `/speckit.specify`
2. Manager refines: `/speckit.clarify` (optional)
3. Manager plans: `/speckit.plan`
4. Manager generates tasks: `/speckit.tasks`
5. Manager assigns tasks to Implementation Agent via APM Task Assignment Prompt.
6. Implementation Agent executes, logs to `.apm/Memory/`, reports back.
7. Manager reviews log, decides next task or phase.

**Source of truth documents (always read before starting a task):**
- `docs/AI_CONTEXT.md` — project overview for AI
- `docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md` — progress + next tasks
- `memory/AI_WORK_PROTOCOL.md` — detailed scope and MUST-ASK rules
- `memory/DECISIONS.md` — architectural decisions log

## Governance

This Constitution supersedes all other practices, inline comments, and verbal agreements.
When conflict exists between this Constitution and any other document, the Constitution wins.

**Amendment procedure:**
1. Identify the amendment (principle change, new section, constraint addition).
2. Manager (Claude Code) records the proposed change in `memory/DECISIONS.md` with
   rationale and impact assessment.
3. User reviews and approves the amendment.
4. Manager updates this file, increments the version, updates `Last Amended` date.
5. Manager runs `/speckit.constitution` to propagate changes to dependent templates.

**Version policy (semantic):**
- MAJOR: Backward-incompatible removal or redefinition of a Core Principle.
- MINOR: New principle, new section, or materially expanded guidance.
- PATCH: Clarification, wording fix, date update, non-semantic refinement.

**Compliance:**
- Every feature plan (`plan.md`) MUST include a "Constitution Check" section that
  verifies the feature design against each applicable Core Principle before Phase 1.
- Every task list (`tasks.md`) MUST include verification tasks aligned with
  Principle IV (Verify-Before-Done).
- Violations found during review MUST be resolved before implementation proceeds.

**Version**: 1.0.0 | **Ratified**: 2026-02-27 | **Last Amended**: 2026-02-27
