# Đề xuất: Hiển thị dữ liệu phân cấp đơn vị dạng cây (Tree) – Phương án tối ưu nhất

**Ngày:** 2026-02-07  
**Phạm vi:** Trang Quản lý đơn vị (B6 – Frontend) + API (tối thiểu)  
**Mục đích:** Triển khai **lần đầu** theo **base chuẩn dữ liệu phân cấp**; đơn vị (Organization) là implementation đầu tiên, tạo nền cho Menu, ReferenceEntity, Form hierarchy, …

**Base và Rule (bắt buộc tuân theo):**  
- **Tài liệu base:** [HIERARCHICAL_DATA_BASE_AND_RULE.md](HIERARCHICAL_DATA_BASE_AND_RULE.md) – chuẩn chung cho mọi dữ liệu phân cấp (API `all=true`, util generic `buildTree<T>`, Table tree, TreeSelect, mở rộng lazy/virtual/`/tree`).  
- **Rule Cursor:** [.cursor/rules/bcdt-hierarchical-data.mdc](../../.cursor/rules/bcdt-hierarchical-data.mdc) – checklist khi thêm/hiển thị dữ liệu phân cấp.

---

## 1. Hiện trạng và ràng buộc

| Hạng mục | Mô tả |
|----------|--------|
| **UI hiện tại** | Table phẳng (flat), một bảng với Mã, Tên, Loại, Cấp, Hoạt động, Thao tác. |
| **Backend** | Entity có `ParentId`, `TreePath`, `Level` (cây 5 cấp). `GET /api/v1/organizations` có filter `parentId`: **không truyền `parentId` = chỉ trả về nút gốc** (ParentId == null). |
| **Yêu cầu** | Hiển thị đơn vị **dạng cây** (tree), chuyên nghiệp và tối ưu. |

**Ràng buộc kỹ thuật:** Cần có đủ dữ liệu để build cây: hoặc một lần “toàn bộ” (flat hoặc nested), hoặc lazy load theo nhánh.

---

## 2. Kiến trúc giải pháp (tổng quan)

```
┌─────────────────────────────────────────────────────────────────┐
│  API (tối thiểu)                                                 │
│  GET /api/v1/organizations?all=true  → trả về toàn bộ (flat)     │
│  hoặc GET /api/v1/organizations/tree → trả về nested (tùy chọn)   │
└─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────┐
│  Frontend                                                        │
│  • useQuery(['organizations', { all: true }])                    │
│  • useMemo(treeData = buildTree(data))     ← O(n), 1 lần khi data │
│  • Table dataSource=treeData, rowKey="id", expandable             │
│  • TreeSelect cho "Đơn vị cha" (treeData, loại trừ bản thân/con)  │
└─────────────────────────────────────────────────────────────────┘
```

- **Một nguồn dữ liệu:** React Query cache `organizations`; tree chỉ là **dẫn xuất** (derived state) từ flat, không lưu tree riêng.
- **Tách lớp:** Util **generic** `buildTree<T>` trong `utils/treeUtils.ts` (dùng chung cho Organization, Menu, …); page chỉ gọi API + `useMemo(buildTree)` + render Table/TreeSelect.

---

## 3. Thay đổi Backend (tối thiểu, đề xuất phê duyệt)

### 3.1. Lấy toàn bộ đơn vị (flat) trong một lần

**Mục đích:** Để FE build cây một lần, một round-trip, không lazy load phức tạp khi quy mô vừa phải.

**Đề xuất:** Thêm query param **`all`** (boolean, optional) cho `GET /api/v1/organizations`:

| Param | Ý nghĩa |
|-------|--------|
| Không truyền `all` hoặc `all=false` | Giữ hành vi hiện tại: `parentId` bắt buộc ngầm định (null = chỉ gốc). |
| `all=true` | Bỏ filter theo `parentId` → trả về **toàn bộ** đơn vị (flat), vẫn áp dụng `organizationTypeId`, `includeInactive`. |

**Ví dụ:** `GET /api/v1/organizations?all=true&includeInactive=true` → danh sách phẳng toàn bộ đơn vị.

**Thay đổi code (gợi ý):**

- Controller: thêm `[FromQuery] bool all = false`.
- Service: `GetListAsync(..., bool all = false, ...)`. Khi `all == true`, không add điều kiện `ParentId == null` / `ParentId == parentId`; chỉ filter IsDeleted, IsActive (nếu !includeInactive), OrganizationTypeId (nếu có).

**Rủi ro:** Khi số lượng đơn vị rất lớn (ví dụ > 2000), response lớn. Khi đó có thể chuyển sang lazy load (xem mục 6).

---

## 4. Frontend – Chuẩn hóa và tối ưu

### 4.1. Util build cây – generic, O(n), an toàn

- **Vị trí:** `src/utils/treeUtils.ts` (theo [HIERARCHICAL_DATA_BASE_AND_RULE.md](HIERARCHICAL_DATA_BASE_AND_RULE.md)).
- **Dùng generic:** `buildTree<T>(flat, options?)` với `BuildTreeOptions<T>`: `idKey` (default `'id'`), `parentKey` (default `'parentId'`), `childrenKey` (default `'children'`), `sortBy` (vd. `(a,b) => (a.displayOrder - b.displayOrder) || (a.code).localeCompare(b.code)`).
- **Cho Organization:** Gọi `buildTree(data, { sortBy: (a, b) => ... })`; type `OrganizationTreeNode = TreeNode<OrganizationDto>` (re-export từ treeUtils).
- **Thuật toán:** O(n): Map id → node; một lần duyệt gắn con vào parent hoặc đẩy xuống gốc nếu parent không tồn tại; sắp xếp gốc và từng children theo `sortBy`. Phòng thủ: parentId lỗi/vòng tròn không crash.

### 4.2. Trang Quản lý đơn vị

- **Data:**  
  - Gọi `organizationsApi.getList({ all: true, includeInactive: true })` (sau khi backend hỗ trợ `all`).  
  - `treeData = useMemo(() => buildTree(data), [data])` — chỉ build lại khi `data` thay đổi.
- **Table:**
  - `dataSource={treeData}`, `rowKey="id"`.
  - Giữ nguyên cột (Mã, Tên, Loại, Cấp, Hoạt động, Thao tác).
  - Tắt phân trang: `pagination={false}` hoặc chỉ hiển thị `showTotal: (t) => 'Tổng ' + t + ' bản ghi'` không chia trang.
  - Mặc định mở cấp 1: `defaultExpandRowKeys` = danh sách `id` của các nút `level === 1` (hoặc tất cả gốc), tránh mở toàn bộ cây khi dữ liệu lớn.
- **Empty/Loading/Error:** Giữ xử lý hiện tại (Empty, Loading, Error state).

### 4.3. Form Modal – Đơn vị cha (TreeSelect, chuyên nghiệp)

- Thay **Select** bằng **TreeSelect** (Ant Design).
- **treeData:** Dùng cùng `buildTree(data)` (đã có sẵn từ page).
- **Khi sửa:** Loại trừ **bản thân** và **mọi con** (descendants) khỏi danh sách chọn được (đồng bộ backend, tránh vòng tròn).
  - Hàm util **generic:** `treeExcludeSelfAndDescendants<T>(tree, selfId, idKey?)` trong `treeUtils.ts`; dùng làm `treeData` của TreeSelect khi `editingId` có giá trị.
- **TreeSelect:** Bật `treeDefaultExpandAll={false}`, có thể `treeLine`, `placeholder="Không có (gốc)"`, `allowClear`, `showSearch` với `filterTreeNode` (tìm theo mã/tên).

### 4.4. Hiệu năng và trải nghiệm

| Biện pháp | Mô tả |
|-----------|--------|
| **useMemo(treeData)** | Chỉ build cây khi `data` thay đổi, tránh build lại mỗi lần render. |
| **defaultExpandRowKeys** | Chỉ mở cấp 1 (hoặc gốc), giảm DOM ban đầu. |
| **rowKey="id"** | Ổn định key, tránh re-mount không cần thiết. |
| **Columns** | Tránh tạo object/hàm mới trong render; có thể `useMemo(columns, [deps])` nếu cần. |
| **Virtual scroll** | Khi tổng số node > 500–1000, cân nhắc bật `virtual` cho Table (Ant Design 5) để giữ FPS ổn định. |

### 4.5. Accessibility và UX

- Table expand/collapse: dùng hành vi mặc định của Ant Design (có thể truy cập bằng bàn phím).
- TreeSelect: bật `showSearch` và `filterTreeNode` để tìm nhanh đơn vị cha.
- Giữ thông báo thành công/lỗi và xác nhận xóa như hiện tại.

---

## 5. Edge cases và validation

| Tình huống | Cách xử lý |
|------------|------------|
| **Dữ liệu rỗng** | Table hiển thị Empty; TreeSelect không có option (hoặc disable). |
| **parentId trỏ ra ngoài / vòng tròn** | Backend đã validate; FE buildTree bỏ qua node lỗi hoặc gắn vào gốc, không crash. |
| **Xóa đơn vị có con** | Giữ logic backend hiện tại (có thể trả CONFLICT nếu cấu hình không cho xóa khi có con). |
| **Sửa đơn vị: chọn chính nó hoặc con làm cha** | TreeSelect loại trừ bản thân + descendants; backend từ chối nếu lỗi. |

---

## 6. Mở rộng sau này (scalability)

Theo [HIERARCHICAL_DATA_BASE_AND_RULE.md](HIERARCHICAL_DATA_BASE_AND_RULE.md):

- **Lazy load:** Không dùng `all=true`; load gốc trước; khi expand gọi `?parentId={id}` và merge children vào cây (state “đã load con”, flat + buildTree lại hoặc append children).
- **Endpoint `/tree`:** `GET /api/v1/organizations/tree` trả về nested; FE `dataSource = response.data` (chuẩn hóa key nếu cần).
- **Virtual scroll:** Bật `virtual` cho Table khi số node > 500–1000 (Ant Design 5).

---

## 7. Kiểm thử (gợi ý)

- **Unit test (buildTree):**
  - Mảng rỗng → `[]`.
  - Một nút gốc (parentId null) → một nút, không children.
  - Nhiều cấp (gốc → con → cháu) → cấu trúc children đúng.
  - parentId trỏ tới id không tồn tại → node đó được đưa vào gốc hoặc bỏ qua, không crash.
- **E2E (tùy chọn):** Mở trang đơn vị → có nút expand; expand một hàng → thấy hàng con; mở Modal Thêm đơn vị → chọn Đơn vị cha từ TreeSelect.

---

## 8. Tóm tắt để phê duyệt

| Hạng mục | Nội dung |
|----------|----------|
| **Backend** | Thêm query param `all=true` cho `GET /api/v1/organizations` để trả về toàn bộ đơn vị (flat). |
| **Frontend** | Util `buildTree` O(n) trong `utils/treeUtils.ts`; `useMemo(treeData)`; Table dạng cây (dataSource có children); tắt phân trang; defaultExpandRowKeys cấp 1; TreeSelect cho Đơn vị cha, loại trừ bản thân + descendants khi sửa. |
| **Chất lượng** | Type rõ ràng, xử lý edge case, unit test buildTree, có hướng mở rộng (lazy, virtual). |
| **Rủi ro** | Thấp; khi số đơn vị rất lớn thì dùng lazy load hoặc endpoint tree. |

**Kết luận:** Triển khai **một lần** theo **base chuẩn** [HIERARCHICAL_DATA_BASE_AND_RULE.md](HIERARCHICAL_DATA_BASE_AND_RULE.md) và rule [bcdt-hierarchical-data.mdc](../../.cursor/rules/bcdt-hierarchical-data.mdc): backend `all=true`, frontend util generic `buildTree<T>` + `treeExcludeSelfAndDescendants<T>`, Table tree + TreeSelect. Organization là implementation đầu tiên; Menu, ReferenceEntity, Form hierarchy sau này dùng cùng base và rule.
