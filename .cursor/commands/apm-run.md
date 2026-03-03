---
priority: 1
command_name: apm-run
description: Đọc task từ inbox, thực thi bằng đúng Implementation Agent, ghi kết quả vào outbox. Dùng "/apm-run" cho current_task.md, hoặc "/apm-run task_2_3" cho .apm/inbox/task_2_3.md
---

Kiểm tra xem lệnh có tham số không:
- Nếu có tham số (ví dụ `/apm-run task_2_3`): đọc file `.apm/inbox/<tham_số>.md` và ghi kết quả vào `.apm/inbox/<tham_số>.result.md`
- Nếu không có tham số: đọc file `.apm/inbox/current_task.md` và ghi kết quả vào `.apm/inbox/current_task.result.md`

Đọc file task đã xác định ở trên.

Từ YAML frontmatter của file đó, lấy trường `agent_assignment` để xác định vai trò agent (ví dụ: `Agent_Backend`, `Agent_Frontend`, `Agent_Security`...).

Tiếp theo đọc file agent tương ứng trong `.cursor/agents/`:
- Agent_Backend → `.cursor/agents/apm-agent-backend.md`
- Agent_Frontend → `.cursor/agents/apm-agent-frontend.md`
- Agent_Security → `.cursor/agents/apm-agent-security.md`
- Agent_Database → `.cursor/agents/apm-agent-database.md`
- Agent_Fullstack → `.cursor/agents/apm-agent-fullstack.md`
- Agent_DevOps → `.cursor/agents/apm-agent-devops.md`
- Agent_TechLead → `.cursor/agents/apm-agent-techlead.md`
- Agent_QA → `.cursor/agents/apm-agent-qa.md`
- Agent_Docs → `.cursor/agents/apm-agent-docs.md`
- Agent_SA → `.cursor/agents/apm-agent-sa.md`
- Agent_BA → `.cursor/agents/apm-agent-ba.md`

Áp dụng system prompt của agent đó, sau đó thực thi toàn bộ task được mô tả trong `.apm/inbox/current_task.md`.

Sau khi hoàn thành, ghi kết quả vào `.apm/inbox/current_task.result.md` theo định dạng:

```markdown
---
task_ref: [task_ref từ current_task.md]
agent: [agent_assignment từ current_task.md]
status: DONE | PARTIAL | BLOCKED
timestamp: [thời điểm hoàn thành]
---

## Kết quả thực thi

[Tóm tắt những gì đã làm]

## Files đã thay đổi

- `path/to/file` – [mô tả thay đổi]

## Memory Log

[Nội dung memory log theo Memory_Log_Guide.md – đã ghi vào file log thực tế]

## Flags

- important_findings: true/false
- compatibility_issue: true/false
- ad_hoc_delegation: true/false

## Ghi chú cho Manager

[Bất kỳ lưu ý nào cần Manager biết]
```

Sau khi ghi xong file result, thông báo: "✅ Task hoàn thành. Claude Code Manager có thể đọc kết quả tại `.apm/inbox/current_task.result.md`"
