# BCDT – Project memory (ghi nhớ)

Tài liệu ngắn để AI "nhớ" ngữ cảnh dự án. Đọc khi bắt đầu task (hoặc khi cần nhắc). **Token: giữ tối thiểu.**

1. **Workflow (bắt buộc):** Plan → Execute → Verify → Reflect. Rule **bcdt-agentic-workflow**: Plan trước (liệt kê bước, file, rủi ro, scope), rồi Execute theo kế hoạch; không thi hành trước khi có Plan; Verify trước khi báo xong; Reflect (cập nhật TONG_HOP + gợi ý tiếp).
2. **Nguồn sự thật task:** TONG_HOP (docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.2, 3.7. Không tạo task mới ngoài TONG_HOP khi user không yêu cầu.
3. **Verify bắt buộc:** Luôn build (tắt BCDT.Api trước) + chạy "Kiểm tra cho AI" / *_TEST_CASES.md; báo Pass/Fail từng bước. Rule always-verify-after-work.
4. **Khi xong task trong TONG_HOP:** Cập nhật TONG_HOP 2.1, 2.2, 3, 4, 5, 8, Version. Rule bcdt-update-tong-hop-after-task.
5. **Đề xuất việc tiếp:** Block "Cách giao AI" copy-paste cho ưu tiên 1. Rule bcdt-next-work-ai-prompt.
6. **Commands:** /bcdt-task (4 phase), /bcdt-verify (Verify), /bcdt-next (đề xuất), /bcdt-auto (tự động 4 phase: Plan → Execute → Verify → Reflect).
