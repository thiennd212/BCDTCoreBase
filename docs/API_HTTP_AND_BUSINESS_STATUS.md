# API: HTTP status và mã lỗi nghiệp vụ (BCDT)

Tài liệu ngắn quy ước dùng **HTTP status** và **mã lỗi nghiệp vụ** giữa Backend (.NET) và Frontend (React).

## 1. Chuẩn response

- **Thành công:** `{ "success": true, "data": ... }` — HTTP 200 hoặc 201.
- **Lỗi:** `{ "success": false, "errors": [ { "code", "message", "field?" } ] }` — HTTP 4xx/5xx.

Chi tiết: `src/BCDT.Api/Common/ApiResponse.cs` (ApiSuccessResponse, ApiErrorResponse).

## 2. HTTP status (Backend)

| HTTP | Ý nghĩa | Khi nào dùng |
|------|----------|----------------|
| 200  | OK       | GET thành công, PUT/PATCH/DELETE thành công. |
| 201  | Created  | POST tạo mới thành công (tùy chọn). |
| 400  | Bad Request | Validation, tham số sai, lỗi nghiệp vụ chung. |
| 401  | Unauthorized | Chưa đăng nhập / token hết hạn. |
| 403  | Forbidden | Đã đăng nhập nhưng không đủ quyền. |
| 404  | Not Found | Tài nguyên không tồn tại (hoặc chưa cấu hình, vd data-binding). |
| 409  | Conflict | Trùng dữ liệu / xung đột (vd mã đã tồn tại). |
| 500  | Server Error | Lỗi hệ thống (exception không xử lý). |

**Quan trọng:** HTTP status chỉ phân loại lỗi. **Nội dung hiển thị cho người dùng** và **logic nghiệp vụ** lấy từ body: `errors[0].message` và `errors[0].code`.

## 3. Mã lỗi nghiệp vụ (code)

Backend dùng `ApiErrorResponse(Code, Message, Field?)`. Mã `code` thống nhất để FE có thể phân nhánh (vd 404 → hiển thị trống, CONFLICT → thông báo trùng).

| Code | Ý nghĩa | Thường kèm HTTP |
|------|---------|------------------|
| NOT_FOUND | Không tìm thấy / chưa cấu hình | 404 |
| CONFLICT | Trùng / xung đột | 409 |
| VALIDATION_FAILED | Dữ liệu không hợp lệ | 400 |
| UNAUTHORIZED | Không xác định được user / token | 401 |
| INVALID_FILE | File không đúng định dạng/yêu cầu | 400 |

Hằng số backend: `ApiErrorCodes` trong `ApiResponse.cs`.

## 4. Frontend: cách dùng

- **Hiển thị lỗi cho user:** luôn dùng `getApiErrorMessage(err)` (ưu tiên `errors[0].message`, fallback theo HTTP status).  
  Ví dụ: `onError: (err) => message.error(getApiErrorMessage(err) || 'Thao tác thất bại')`.

- **Phân nhánh logic (tùy chọn):**
  - `getApiErrorCode(err)` → mã nghiệp vụ.
  - `getApiErrorStatus(err)` → HTTP status.
  - `isApiNotFound(err)` → 404 hoặc NOT_FOUND.
  - `isApiConflict(err)` → 409 hoặc CONFLICT.

- **Kiểu TypeScript:** `ApiSuccessResponse<T>`, `ApiErrorResponseBody`, `ApiErrorItem` trong `apiClient.ts`.

Sau khi interceptor xử lý, lỗi reject vẫn mang `.message`, `.code`, `.status` (nếu có) để các helper trên hoạt động.

## 5. Tóm tắt

- **Backend:** Trả đúng HTTP status + body chuẩn `success`/`errors`; dùng `ApiErrorCodes` cho `code`.
- **Frontend:** Hiển thị lỗi bằng `getApiErrorMessage(err)`; cần phân nhánh thì dùng `getApiErrorCode` / `isApiNotFound` / `isApiConflict`.

Last updated: 2026-02-06
