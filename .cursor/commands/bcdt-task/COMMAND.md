# /bcdt-task – Bắt đầu task BCDT (Plan → Execute → Verify → Reflect)

**Token: tham chiếu, không lặp nội dung dài.** Tuân thủ rule **bcdt-agentic-workflow**: tách Plan và Execute, không thi hành trước khi có kế hoạch.

1. **Plan**
   - Đọc **docs/AI_CONTEXT.md**. Mở **docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md** mục **3.2** → chọn task (theo user hoặc ưu tiên 1 từ 3.7). Mục **3.3/3.5/3.7** → lấy block "Cách giao AI".
   - **Liệt kê bản kế hoạch:** task con, thứ tự bước, file/agent/skill, rủi ro (vd BCDT.Api lock), scope (làm gì / không làm gì). Không sửa code ở bước này.

2. **Execute**
   - Thực hiện **đúng** theo bản kế hoạch và block (tài liệu, Rules, Agent/Skill, yêu cầu). Task phức tạp → dùng mcp_task với subagent_type tương ứng. Không thêm scope ngoài kế hoạch.

3. **Verify**
   - Build (tắt BCDT.Api trước); chạy "Kiểm tra cho AI" / *_TEST_CASES.md, Postman. Báo Pass/Fail từng bước. Fail → sửa rồi Verify lại (rule **always-verify-after-work**).

4. **Reflect**
   - Xong → cập nhật TONG_HOP (rule bcdt-update-tong-hop-after-task). Trả lời: tóm tắt + Pass/Fail + gợi ý `/bcdt-next`.

**Tự động:** Không hỏi xác nhận; làm trực tiếp. Chỉ hỏi nếu thiếu thông tin (vd user không nêu tên task và ưu tiên 1 không rõ).
