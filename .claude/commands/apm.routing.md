---
description: APM Agent Routing Guide – tham chiếu để Manager chọn đúng agent cho từng loại task. Không phải skill thực thi – chỉ là reference guide.
---

# APM – Agent Routing Guide (BCDT)

Tài liệu tham chiếu cho `/apm.manager` khi viết Task Assignment Prompts.
Mỗi task type → agent phù hợp → rules bắt buộc → domain experts có thể invoke.

---

## Routing Map

### Tầng 2 – Analysis & Design

| Task Type | `agent_assignment` | Domain experts gợi ý |
|---|---|---|
| Thu thập yêu cầu nghiệp vụ mới | `Agent_BA` | bcdt-business-reviewer, bcdt-form-analyst, bcdt-workflow-designer |
| Viết / cập nhật spec.md | `Agent_BA` | bcdt-business-reviewer |
| Gap analysis yêu cầu vs code | `Agent_BA` | bcdt-business-reviewer, bcdt-org-admin |
| Thiết kế kiến trúc kỹ thuật | `Agent_SA` | bcdt-auth-expert, bcdt-data-binding, bcdt-hybrid-storage |
| Viết / cập nhật plan.md | `Agent_SA` | bcdt-form-structure-indicators, bcdt-aggregation-builder |
| Thiết kế API contracts | `Agent_SA` | bcdt-auth-expert |
| Thiết kế DB schema mới | `Agent_SA` + `Agent_Database` | bcdt-hybrid-storage |
| Record DECISIONS.md | `Agent_SA` | — |

### Tầng 3 – Engineering

| Task Type | `agent_assignment` | Rules bắt buộc |
|---|---|---|
| Domain entity, service, validator | `Agent_Backend` | bcdt-backend, bcdt-project |
| API controller, DTO | `Agent_Backend` | bcdt-api, bcdt-backend |
| EF Core migration, DbContext | `Agent_Database` | bcdt-database, bcdt-project |
| SQL script, stored procedure, index | `Agent_Database` | bcdt-database |
| RLS / session context changes | `Agent_Database` + MUST-ASK | bcdt-database, bcdt-auth-expert |
| React page, component, hook | `Agent_Frontend` | bcdt-frontend, bcdt-project |
| API client (TypeScript) | `Agent_Frontend` | bcdt-frontend |
| Fortune Sheet integration | `Agent_Frontend` | bcdt-excel |
| Cây phân cấp (hierarchical UI) | `Agent_Frontend` | bcdt-hierarchical-data |
| Small feature BE + FE (< 5 files each) | `Agent_FullStack` | bcdt-backend + bcdt-frontend |
| RUNBOOK / config / appsettings | `Agent_DevOps` | always-verify-after-work |
| Hangfire job setup | `Agent_DevOps` + MUST-ASK | bcdt-project |
| Health check, rate limit, middleware | `Agent_DevOps` | bcdt-project |
| Production deployment prep | `Agent_DevOps` | always-verify-after-work |

### Tầng 4 – Quality Gates (luôn chạy theo thứ tự)

| Gate | `agent_assignment` | Trigger |
|---|---|---|
| Code review, Clean Arch compliance | `Agent_TechLead` | Sau mọi Engineering task |
| OWASP, RLS, JWT audit | `Agent_Security` | Sau task chạm auth/security/RLS |
| E2E, Postman, functional test | `Agent_QA` | Sau mọi implementation phase |

**Thứ tự bắt buộc:** TechLead → Security → QA → Docs → DevOps (deploy)

### Tầng 5 – Operations

| Task Type | `agent_assignment` |
|---|---|
| Cập nhật TONG_HOP, RUNBOOK, USER_GUIDE | `Agent_Docs` |
| Cập nhật Postman collection | `Agent_Docs` |
| Cập nhật Swagger / OpenAPI summary | `Agent_Docs` |
| Viết de_xuat_trien_khai document | `Agent_Docs` |
| Deploy, verify /health | `Agent_DevOps` |

---

## MUST-ASK Checklist (Principle V)

Trước khi giao bất kỳ task nào liên quan đến các mục dưới đây,
Manager **PHẢI** ghi rõ trong Task Assignment Prompt rằng đây là MUST-ASK area
và Implementation Agent phải dừng, confirm trước khi thực thi:

| Area | Agent liên quan |
|---|---|
| RLS / SESSION_CONTEXT / sp_SetUserContext | Agent_Database, Agent_Backend |
| Middleware order thay đổi | Agent_Backend, Agent_DevOps |
| Hangfire job đọc/ghi bảng RLS | Agent_DevOps, Agent_Backend |
| Workbook flow contract | Agent_Backend, Agent_FullStack |
| Dashboard / AppReadOnlyDbContext | Agent_Backend, Agent_Database |
| JWT config, refresh token logic | Agent_Security, Agent_Backend |
| Production config, CORS, rate limit | Agent_DevOps, Agent_Security |
| DB schema production risk | Agent_Database |

---

## Agent File Locations

| Agent | File (Cursor) |
|---|---|
| Agent_BA | `.cursor/agents/apm-agent-ba.md` |
| Agent_SA | `.cursor/agents/apm-agent-sa.md` |
| Agent_Backend | `.cursor/agents/apm-agent-backend.md` |
| Agent_Frontend | `.cursor/agents/apm-agent-frontend.md` |
| Agent_FullStack | `.cursor/agents/apm-agent-fullstack.md` |
| Agent_Database | `.cursor/agents/apm-agent-database.md` |
| Agent_DevOps | `.cursor/agents/apm-agent-devops.md` |
| Agent_TechLead | `.cursor/agents/apm-agent-techlead.md` |
| Agent_Security | `.cursor/agents/apm-agent-security.md` |
| Agent_QA | `.cursor/agents/apm-agent-qa.md` |
| Agent_Docs | `.cursor/agents/apm-agent-docs.md` |

---

## Task Assignment YAML Template

```yaml
---
task_ref: "Task X.Y - [Title]"
agent_assignment: "Agent_Backend"
memory_log_path: ".apm/Memory/Phase_XX_slug/Task_X_Y_slug.md"
execution_type: "single-step | multi-step"
dependency_context: false
ad_hoc_delegation: false
---
```

---

## Parallel Assignment Rules

Tasks có thể chạy song song khi:
- Không dùng chung file (khác layer hoàn toàn)
- Không có producer-consumer dependency
- Ví dụ: Agent_Backend (service) + Agent_Frontend (page riêng) + Agent_Database (migration riêng)

Tasks PHẢI tuần tự khi:
- Phase 2 (Design) PHẢI xong trước Phase 3 (Engineering)
- Engineering PHẢI xong trước Tầng 4 (Quality Gates)
- TechLead PHẢI xong trước Security PHẢI xong trước QA
- QA Pass PHẢI xong trước Agent_Docs và Agent_DevOps (deploy)
