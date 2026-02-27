# Base và Rule: Dữ liệu phân cấp (Hierarchical Data) – BCDT

**Ngày:** 2026-02-07  
**Mục đích:** Chuẩn hóa **một lần** cho mọi dữ liệu phân cấp (Organization, Menu, ReferenceEntity, Form hierarchy, …). Làm base và rule để triển khai thống nhất, tối ưu và dễ mở rộng.

---

## 1. Phạm vi áp dụng

**Áp dụng cho mọi entity có quan hệ cha–con (ParentId / TreePath / Level):**

| Entity | Bảng | Ghi chú |
|--------|------|---------|
| Đơn vị | BCDT_Organization | ParentId, TreePath, Level (5 cấp) |
| Menu | BCDT_Menu | ParentId (authorization) |
| ReferenceEntity | BCDT_ReferenceEntity | ParentId (reference data) |
| Form / biểu mẫu (tương lai) | BCDT_FormDefinition, … | Khi có phân cấp |

**Rule:** Khi thêm hoặc hiển thị **bất kỳ** dữ liệu phân cấp nào, **bắt buộc** tuân theo base này (API convention + FE utils + Table tree + TreeSelect cho trường “cha”).

---

## 2. Kiến trúc tổng quan (base)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  BACKEND – Convention cho API phân cấp                                        │
│  • GET /api/v1/{resource}?all=true  → trả về toàn bộ (flat)                  │
│  • GET /api/v1/{resource}/tree      → (tùy chọn) trả về nested { children }  │
│  • Khi không có all=true: parentId filter như hiện tại (null = gốc)          │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  FRONTEND – Base (dùng chung cho mọi resource phân cấp)                       │
│  • utils/treeUtils.ts: buildTree<T>, treeExcludeSelfAndDescendants<T>, types │
│  • useQuery + useMemo(treeData = buildTree(data))                            │
│  • Table: dataSource=treeData, rowKey=idKey, defaultExpandRowKeys (cấp 1)    │
│  • Form “cha”: TreeSelect với treeData; khi sửa loại trừ self + descendants  │
└─────────────────────────────────────────────────────────────────────────────┘
```

- **Một nguồn dữ liệu:** React Query cache; tree là **derived state** (useMemo từ flat).
- **Tái sử dụng:** Util generic `<T>` dùng cho Organization, Menu, ReferenceEntity, …

---

## 3. Backend – Convention (bắt buộc khi có dữ liệu phân cấp)

### 3.1. List endpoint – Param `all` (chuẩn)

| Param | Ý nghĩa |
|-------|--------|
| Không truyền `all` hoặc `all=false` | Giữ hành vi hiện tại: filter theo `parentId` (null = chỉ gốc, hoặc theo parentId cụ thể). |
| **`all=true`** | Bỏ filter theo `parentId` → trả về **toàn bộ** bản ghi (flat). Các filter khác (isActive, typeId, …) vẫn áp dụng. |

**Ví dụ:**  
`GET /api/v1/organizations?all=true&includeInactive=true` → toàn bộ đơn vị (flat).  
`GET /api/v1/menus?all=true` → toàn bộ menu (flat).

**Triển khai (gợi ý):** Controller thêm `[FromQuery] bool all = false`; Service khi `all == true` không add điều kiện `ParentId == null` / `ParentId == parentId`.

### 3.2. Endpoint `/tree` (tùy chọn – mở rộng)

Khi cần giảm tải FE hoặc payload rất lớn, có thể thêm:

- **GET /api/v1/{resource}/tree**  
  Trả về JSON **lồng** (mỗi node có `children: []`). FE chỉ cần `dataSource = response.data` (có thể chuẩn hóa key nếu backend dùng tên khác).

**Khi nào dùng:**  
- Ưu tiên: **`all=true` + buildTree ở FE** (đơn giản, một convention cho mọi resource).  
- Dùng `/tree` khi: payload flat quá lớn, hoặc backend đã có sẵn logic build cây (CTE/recursive).

---

## 4. Frontend – Base utils (generic, dùng chung)

### 4.1. Vị trí và type

- **File:** `src/utils/treeUtils.ts` (hoặc `src/utils/hierarchicalData.ts`).
- **Type generic:**

```ts
// Node cây: bản ghi gốc + children (đệ quy)
export type TreeNode<T> = T & { children?: TreeNode<T>[] }

// Tuỳ chọn buildTree: tên field (để dùng cho entity khác Organization)
export interface BuildTreeOptions<T> {
  idKey?: keyof T & string           // default 'id'
  parentKey?: keyof T & string      // default 'parentId'
  childrenKey?: keyof T & string    // default 'children'
  sortBy?: (a: T, b: T) => number    // sắp xếp trước khi gắn children
}
```

### 4.2. Hàm `buildTree<T>`

- **Input:** `flat: T[]`, `options?: BuildTreeOptions<T>`.
- **Output:** `TreeNode<T>[]` (chỉ nút gốc; con nằm trong `children`).
- **Thuật toán O(n):**
  1. Map từng phần tử → node (shallow copy + `children: []`).
  2. Một lần duyệt: nếu `parentKey == null/undefined` → đẩy vào mảng gốc; ngược lại append vào `map.get(parentId).children` (nếu không tìm thấy parent → đẩy xuống gốc để không mất dữ liệu).
  3. Sắp xếp gốc và từng `children` theo `sortBy` (nếu có; ví dụ `displayOrder` rồi `code`).
- **Phòng thủ:** Dữ liệu lỗi (vòng tròn, parentId không tồn tại) không gây crash; có thể log warning.

### 4.3. Hàm `treeExcludeSelfAndDescendants<T>`

- **Input:** `tree: TreeNode<T>[]`, `selfId: Id`, `idKey?: keyof T & string` (default `'id'`).
- **Output:** Tree mới (clone) đã **loại bỏ** node có `id === selfId` và **toàn bộ con** (descendants).
- **Dùng cho:** TreeSelect “chọn cha” khi **sửa** bản ghi, tránh chọn chính nó hoặc con làm cha (đồng bộ với validation backend).

### 4.4. Chuyển sang định dạng Ant Design TreeSelect (tùy chọn)

- **Hàm:** `toAntdTreeData<T>(tree, titleKey, valueKey)` → `{ title, value, key, children }[]` cho TreeSelect.
- Hoặc mỗi resource tự map (Organization: title = `${code} - ${name}`, value = id).

---

## 5. UI – Convention (Table tree + TreeSelect)

### 5.1. Trang danh sách (list dạng cây)

| Yêu cầu | Cách làm |
|---------|----------|
| **Data** | `useQuery` gọi API với `all=true` (sau khi backend hỗ trợ). |
| **Tree** | `treeData = useMemo(() => buildTree(data, options), [data])`. |
| **Table** | `dataSource={treeData}`, `rowKey={idKey}` (vd. `"id"`). Giữ cột như list phẳng; Thao tác (Sửa/Xóa) như hiện tại. |
| **Phân trang** | `pagination={false}` hoặc chỉ `showTotal: (t) => 'Tổng ' + t + ' bản ghi'` (không chia trang theo số). |
| **Mở mặc định** | `defaultExpandRowKeys` = danh sách id cấp 1 (hoặc chỉ gốc), không `defaultExpandAllRows` khi dữ liệu lớn. |
| **Empty/Loading/Error** | Giữ xử lý như trang list phẳng. |

### 5.2. Form Modal – Trường “cha” (parent)

| Yêu cầu | Cách làm |
|---------|----------|
| **Component** | **TreeSelect** (Ant Design), không Select phẳng. |
| **treeData** | Cùng `buildTree(data)` hoặc `toAntdTreeData(buildTree(data), ...)`. |
| **Khi sửa** | `treeData` = `treeExcludeSelfAndDescendants(tree, editingId)` để không chọn được bản thân và con. |
| **UX** | `placeholder` (vd. "Không có (gốc)"), `allowClear`, `showSearch`, `filterTreeNode` (tìm theo mã/tên). |

### 5.3. Hiệu năng và mở rộng

| Biện pháp | Mô tả |
|-----------|--------|
| **useMemo(treeData)** | Chỉ build cây khi `data` thay đổi. |
| **defaultExpandRowKeys** | Chỉ mở cấp 1 (hoặc gốc). |
| **rowKey ổn định** | Luôn dùng id (vd. `rowKey="id"`). |
| **Virtual scroll** | Khi tổng node > 500–1000: bật `virtual` cho Table (Ant Design 5). |
| **Lazy load** | Khi không dùng `all=true`: load gốc, khi expand gọi API `?parentId={id}` và merge children vào cây (xem mục 6). |

---

## 6. Mở rộng sau này (scalability)

### 6.1. Lazy load (load con khi expand)

- **API:** Giữ `GET /api/v1/{resource}?parentId={id}` (không `all`).
- **FE:** Ban đầu chỉ gọi không truyền `parentId` → chỉ gốc. Khi user expand node, gọi `parentId=node.id` và merge kết quả vào state (flat hoặc cây). Có thể dùng `flatMap` + `buildTree` lại sau mỗi lần merge, hoặc append `children` trực tiếp vào node.
- **State:** “Đã load con” theo node (vd. Set<id> hoặc flag trên node) để không gọi lại.

### 6.2. Endpoint `/tree`

- **GET /api/v1/{resource}/tree** trả về nested. FE: `dataSource = response.data` (có thể map key nếu cần).
- Dùng khi backend đã tối ưu (CTE, recursive) hoặc muốn một nguồn duy nhất cho cây.

### 6.3. Virtual scroll

- Table Ant Design 5: bật `virtual` khi số node > ngưỡng (vd. 500) để giữ FPS.

---

## 7. Edge cases và validation

| Tình huống | Cách xử lý |
|------------|------------|
| Dữ liệu rỗng | Table Empty; TreeSelect không option hoặc disable. |
| parentId trỏ ra ngoài / vòng tròn | Backend validate; FE buildTree đưa node lỗi xuống gốc hoặc bỏ qua, không crash. |
| Xóa node có con | Theo logic backend (vd. CONFLICT nếu không cho xóa khi có con). |
| Sửa: chọn chính nó hoặc con làm cha | TreeSelect dùng treeExcludeSelfAndDescendants; backend từ chối nếu lỗi. |

---

## 8. Kiểm thử (gợi ý)

- **Unit test (buildTree):** Rỗng; một gốc; nhiều cấp; parentId không tồn tại / vòng tròn → không crash.
- **Unit test (treeExcludeSelfAndDescendants):** Loại đúng node + descendants; id không tồn tại → tree giữ nguyên.
- **E2E (tùy chọn):** Trang list cây → expand → thấy con; Modal → chọn cha từ TreeSelect.

---

## 9. Tóm tắt – Base và Rule

| Hạng mục | Nội dung |
|----------|----------|
| **Backend** | List endpoint hỗ trợ **`all=true`** để trả về toàn bộ (flat). (Tùy chọn: `/tree` trả về nested.) |
| **Frontend** | **utils/treeUtils.ts** generic: `buildTree<T>`, `treeExcludeSelfAndDescendants<T>`, `TreeNode<T>`, options (idKey, parentKey, sortBy). |
| **UI** | Table với `dataSource=treeData`, tắt phân trang, defaultExpandRowKeys cấp 1; Form trường “cha” dùng **TreeSelect** với treeData, khi sửa loại trừ self + descendants. |
| **Mở rộng** | Lazy load (parentId khi expand), endpoint `/tree`, virtual scroll khi node > ngưỡng. |
| **Rule** | Mọi dữ liệu phân cấp (Organization, Menu, ReferenceEntity, …) **bắt buộc** theo base này. |

**Rule Cursor:** File `.cursor/rules/bcdt-hierarchical-data.mdc` tham chiếu tài liệu này và checklist khi thêm/hiển thị dữ liệu phân cấp.

---

## 10. Kiểm tra cho AI (Phân cấp Menu)

Đã áp dụng base cho **Menu**: API `GET /api/v1/menus?all=true` trả flat; FE dùng `buildTree`, `treeExcludeSelfAndDescendants`, Table tree, TreeSelect (khi sửa loại trừ self + descendants). Trang: Quản lý menu (MenusPage).

| Bước | Nội dung | Cách kiểm tra |
|------|----------|----------------|
| 1 | Build BE | `dotnet build src/BCDT.Api/BCDT.Api.csproj` (tắt BCDT.Api trước). Kỳ vọng: thành công. |
| 2 | Build FE | `npm run build` trong `src/bcdt-web`. Kỳ vọng: thành công. |
| 3 | API all=true | Gọi `GET /api/v1/menus?all=true` (có Bearer token). Kỳ vọng: 200, body `data` là mảng flat (mỗi item có `id`, `parentId`, `name`, …), không nested `children`. |
| 4 | Trang Menu – cây | Mở trang Quản lý menu; bảng hiển thị dạng cây (có expand), đúng thứ tự DisplayOrder/name. |
| 5 | TreeSelect khi sửa | Mở Sửa một menu có con; trường "Menu cha" không chứa chính nó và không chứa các menu con (đã loại trừ). |
| 6 | DevTools Console | Mở F12 → Console: không error, không warning. |

### 10.1. Kiểm tra cho AI (Phân cấp ReferenceEntity)

Đã áp dụng base cho **ReferenceEntity**: API `GET /api/v1/reference-entities?entityTypeId=&all=true` trả flat; FE dùng `buildTree`, `treeExcludeSelfAndDescendants`, Table tree, TreeSelect (khi sửa loại trừ self + descendants). Trang: Dữ liệu tham chiếu (phân cấp) – `/reference-entities`.

| Bước | Nội dung | Cách kiểm tra |
|------|----------|----------------|
| 1 | Build BE | `dotnet build src/BCDT.Api/BCDT.Api.csproj` (tắt BCDT.Api trước). Kỳ vọng: thành công. |
| 2 | Build FE | `npm run build` trong `src/bcdt-web`. Kỳ vọng: thành công. |
| 3 | API types | Gọi `GET /api/v1/reference-entity-types`. Kỳ vọng: 200, body `data` là mảng loại thực thể. |
| 4 | API all=true | Gọi `GET /api/v1/reference-entities?entityTypeId=1&all=true&includeInactive=true` (có Bearer token). Kỳ vọng: 200, body `data` là mảng flat (id, parentId, entityTypeId, code, name, …). |
| 5 | Trang Reference Entities – cây | Mở trang Dữ liệu tham chiếu; chọn loại thực thể; bảng hiển thị dạng cây (expand), đúng thứ tự displayOrder/code. |
| 6 | TreeSelect khi sửa | Sửa một bản ghi có con; trường "Bản ghi cha" không chứa chính nó và không chứa các bản ghi con. |
| 7 | DevTools Console | F12 → Console: không error, không warning. |

### 10.2. Kiểm tra cho AI (CRUD ReferenceEntityType)

API **ReferenceEntityType** đã có đủ CRUD: GET list, GET {id}, POST (tạo), PUT {id} (cập nhật), DELETE {id} (xóa chỉ khi chưa có ReferenceEntity thuộc type; 409 nếu đã có).

| Bước | Nội dung | Cách kiểm tra |
|------|----------|----------------|
| 1 | Build BE | `dotnet build src/BCDT.Api/BCDT.Api.csproj` (tắt BCDT.Api trước). Kỳ vọng: thành công. |
| 2 | POST type | Gọi `POST /api/v1/reference-entity-types` body `{ "code": "LOAI_TEST", "name": "Loại test", "isActive": true }`. Kỳ vọng: 201, body `data` có id, code, name. |
| 3 | GET by id | Gọi `GET /api/v1/reference-entity-types/{id}` với id vừa tạo. Kỳ vọng: 200, data khớp. |
| 4 | PUT type | Gọi `PUT /api/v1/reference-entity-types/{id}` body `{ "name": "Loại test (cập nhật)", "isActive": true }`. Kỳ vọng: 200. |
| 5 | DELETE (type có entity) | Gọi `DELETE /api/v1/reference-entity-types/1` (nếu type 1 đã có reference entity). Kỳ vọng: 409 Conflict. |
| 6 | DELETE (type không có entity) | Tạo type mới rồi DELETE ngay. Kỳ vọng: 200. |

### 10.3. Kiểm tra cho AI (FE quản lý Loại thực thể – ReferenceEntityTypesPage)

Trang **Loại thực thể tham chiếu** (`/reference-entity-types`): bảng danh sách (Mã, Tên, Mô tả, Trạng thái), nút Thêm/Sửa/Xóa, Modal CRUD (Code disabled khi sửa). Gọi API GET/POST/PUT/DELETE reference-entity-types.

| Bước | Nội dung | Cách kiểm tra |
|------|----------|----------------|
| 1 | Build FE | `npm run build` trong `src/bcdt-web`. Kỳ vọng: thành công. |
| 2 | Mở trang | Vào `/reference-entity-types`. Bảng hiển thị danh sách loại (nếu có). |
| 3 | Thêm loại | Nút Thêm → nhập Mã, Tên (Mô tả tùy chọn), Đang hoạt động → Tạo. Kỳ vọng: thành công, bảng cập nhật. |
| 4 | Sửa loại | Nút Sửa một dòng → đổi Tên/Mô tả/Trạng thái → Cập nhật. Kỳ vọng: thành công. Mã không đổi (disabled). |
| 5 | Xóa loại | Xóa loại chưa có bản ghi tham chiếu: 200. Xóa loại đã có bản ghi: 409 (message lỗi). |
| 6 | DevTools Console | F12 → Console: không error, không warning. |

**E2E tự động (bước 2–5):** file `src/bcdt-web/e2e/reference-entity-types.spec.ts`. Chạy: `npm run test:e2e` trong `src/bcdt-web` (cần BE API tại http://localhost:5080). Bước 6 (Console) vẫn kiểm tra thủ công.

Khi hoàn thành task phân cấp Menu/ReferenceEntity, CRUD ReferenceEntityType (BE/FE) hoặc FE Loại thực thể: chạy đủ các bước tương ứng (mục 10, 10.1, 10.2, 10.3), báo **Pass** hoặc **Fail** từng bước trước khi báo xong.
