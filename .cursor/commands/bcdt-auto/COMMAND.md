# /bcdt-auto – Tự động 4 phase: ưu tiên 1 → Plan → Execute → Verify → Reflect

**Một lệnh chạy trọn chu kỳ.** Tuân thủ rule **bcdt-agentic-workflow**. Không hỏi xác nhận; chỉ dừng nếu thiếu thông tin hoặc lỗi không xử lý được.

1. **Plan**
   - Lấy ưu tiên 1: docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md mục **3.7** → công việc đầu tiên chưa ~~gạch~~. Mục **3.2** → Tài liệu, Rules, Agent, Skill. Mục **3.3/3.5/3.7** → block "Cách giao AI".
   - **Liệt kê bản kế hoạch:** bước, file, agent/skill, rủi ro, scope. Không Execute trước khi có kế hoạch.

2. **Execute**
   - Làm đúng theo bản kế hoạch và block (đọc tài liệu, dùng Agent/Skill). Subagent (mcp_task) nếu phù hợp. Không thêm scope ngoài kế hoạch.

3. **Verify**
   - Build (tắt BCDT.Api trước); chạy "Kiểm tra cho AI" / *_TEST_CASES.md; báo Pass/Fail từng bước. Nếu Fail → sửa và lặp; không báo xong đến khi Pass.

4. **Reflect**
   - Task xong → rule bcdt-update-tong-hop-after-task (2.1, 2.2, 3, 4, 5, 8, Version). Trả lời: tóm tắt + verify Pass/Fail + "Công việc tiếp: /bcdt-next hoặc /bcdt-auto lần nữa."

**Tự động:** Không dừng để hỏi; chỉ hỏi nếu ưu tiên 1 không xác định được hoặc block Cách giao AI không tồn tại.
