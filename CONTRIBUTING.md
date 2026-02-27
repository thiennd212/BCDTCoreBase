# Đóng góp (Contributing)

Hướng dẫn ngắn gọn khi đóng góp code hoặc tài liệu cho dự án BCDT.

## Branch

- **feature/xxx** — Tính năng mới (vd: `feature/form-export`)
- **fix/xxx** — Sửa lỗi (vd: `fix/login-timeout`)
- **docs/xxx** — Chỉ sửa tài liệu (vd: `docs/api-response`)

## Commit

- Dùng message rõ ràng; ưu tiên tiếng Việt hoặc tiếng Anh thống nhất trong repo.
- Gợi ý prefix: `feat:`, `fix:`, `docs:`, `refactor:`, `test:` (vd: `feat: thêm API danh sách biểu mẫu`).

## Trước khi merge

- Chạy **unit test** và **integration test** (nếu có): `dotnet test` / `npm run test`.
- Chạy **lint**: đảm bảo không còn lỗi lint trong phần code bạn sửa.
- Build thành công: `dotnet build`, `npm run build`.

## Changelog

- Khi **phát hành phiên bản** hoặc có **thay đổi đáng chú ý** (tính năng mới, sửa lỗi quan trọng, thay đổi breaking): cập nhật [CHANGELOG.md](CHANGELOG.md).
- Thêm mục vào **[Unreleased]** (Added/Changed/Fixed/...) hoặc tạo version mới (vd: `[0.2.0] - YYYY-MM-DD`) khi release.

## Tài liệu và chuẩn dự án

- Backend/API: tuân thủ [BCDT Project Standards](.cursor/rules/bcdt-project.mdc) và [Senior Fullstack Standards](.cursor/rules/senior-fullstack-standards.mdc).
- API response/error: theo [04. Giải pháp kỹ thuật – API Response & Error Format](docs/script_core/04.GIAI_PHAP_KY_THUAT.md#7-api-response--error-format).
- Workflow và khi nào dùng Skill/Agent: xem [WORKFLOW_GUIDE.md](docs/WORKFLOW_GUIDE.md).

---

**Version:** 1.0  
**Last Updated:** 2026-02-03
