# Task S2.4 FE – Nút Nhân bản biểu mẫu

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – TypeScript clean
**Size:** SMALL (2 files)

## Việc đã làm

### formsApi.ts

Thêm method `clone`:
```typescript
clone: async (id: number, body: { newCode: string; newName: string }): Promise<FormDefinitionDto> => {
  const res = await apiClient.post<{ success: boolean; data: FormDefinitionDto }>(
    `/api/v1/forms/${id}/clone`, body)
  if (!res.data?.data) throw new Error('Nhân bản biểu mẫu thất bại')
  return res.data.data
},
```

### FormsPage.tsx

- Import `CopyOutlined` từ antd icons
- Thêm state: `cloneModalOpen`, `cloningRecord`, `cloneForm`, `cloneFormRef`
- Thêm `useFocusFirstInModal` + `useScrollPageTopWhenModalOpen` cho clone modal
- Thêm `cloneMutation` (on success → navigate `/forms/${data.id}/config`)
- Thêm helper `openClone(record)` – pre-fill `_COPY` / `(bản sao)`
- Thêm action "Nhân bản" trong TableActions (giữa "Sửa" và "Xóa")
- Thêm Clone Modal với 2 fields: newCode (required), newName (required)
