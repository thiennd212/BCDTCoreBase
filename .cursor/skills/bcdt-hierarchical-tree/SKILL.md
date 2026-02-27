---
name: bcdt-hierarchical-tree
description: Implement hierarchical data display (tree) for BCDT. Backend adds all=true to list endpoint; Frontend adds treeUtils (buildTree, treeExcludeSelfAndDescendants), Table tree, TreeSelect for parent. Use when user says "dữ liệu phân cấp", "hiển thị cây", "tree table", "TreeSelect", "đơn vị dạng cây", or entity has ParentId.
---

# BCDT Hierarchical Tree

Implement tree display for entities with ParentId (Organization, Menu, ReferenceEntity, …) following [HIERARCHICAL_DATA_BASE_AND_RULE.md](../../../docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) and rule **bcdt-hierarchical-data**.

## Workflow

1. **Backend:** List endpoint supports `all=true` → return full flat list.
2. **Frontend:** Add/use `utils/treeUtils.ts` (buildTree&lt;T&gt;, treeExcludeSelfAndDescendants&lt;T&gt;).
3. **List page:** Table with dataSource = treeData (useMemo buildTree), rowKey, pagination false or showTotal, defaultExpandRowKeys.
4. **Form parent field:** TreeSelect with treeData; when editing use treeExcludeSelfAndDescendants(tree, editingId).

---

## 1. Backend – List endpoint param `all`

```csharp
// Controller
[HttpGet]
public async Task<IActionResult> GetList(
    [FromQuery] int? parentId,
    [FromQuery] bool all = false,  // when true: return full flat list
    [FromQuery] bool includeInactive = false,
    CancellationToken cancellationToken = default)
{
    var result = await _service.GetListAsync(parentId, all, includeInactive, cancellationToken);
    return Ok(new ApiSuccessResponse<List<OrganizationDto>>(result.Data!));
}

// Service: when all == true, do NOT filter by ParentId; return full flat list.
public async Task<Result<List<OrganizationDto>>> GetListAsync(int? parentId, bool all, bool includeInactive, ...)
{
    var query = _db.Organizations.AsNoTracking().Where(o => !o.IsDeleted);
    if (!includeInactive) query = query.Where(o => o.IsActive);
    if (!all)
    {
        if (parentId.HasValue)
            query = query.Where(o => o.ParentId == parentId.Value);
        else
            query = query.Where(o => o.ParentId == null);
    }
    // ... order, select, ToListAsync
}
```

---

## 2. Frontend – utils/treeUtils.ts

```ts
// TreeNode<T> = T & { children?: TreeNode<T>[] }
export type TreeNode<T> = T & { children?: TreeNode<T>[] }

export interface BuildTreeOptions<T> {
  idKey?: keyof T & string
  parentKey?: keyof T & string
  childrenKey?: keyof T & string
  sortBy?: (a: T, b: T) => number
}

export function buildTree<T extends Record<string, unknown>>(
  flat: T[],
  options: BuildTreeOptions<T> = {}
): TreeNode<T>[] {
  const idKey = (options.idKey ?? 'id') as keyof T
  const parentKey = (options.parentKey ?? 'parentId') as keyof T
  const childrenKey = (options.childrenKey ?? 'children') as keyof TreeNode<T>
  const sortBy = options.sortBy

  const map = new Map<unknown, TreeNode<T>>()
  for (const item of flat) {
    const node = { ...item, [childrenKey]: [] } as TreeNode<T>
    map.set(item[idKey], node)
  }
  const roots: TreeNode<T>[] = []
  for (const item of flat) {
    const node = map.get(item[idKey])!
    const parentId = item[parentKey]
    if (parentId == null || parentId === '') {
      roots.push(node)
    } else {
      const parent = map.get(parentId)
      if (parent && parent[childrenKey]) (parent[childrenKey] as TreeNode<T>[]).push(node)
      else roots.push(node)
    }
  }
  const sort = (nodes: TreeNode<T>[]) => {
    if (sortBy) nodes.sort((a, b) => sortBy(a, b))
    nodes.forEach((n) => n[childrenKey]?.length && sort(n[childrenKey] as TreeNode<T>[]))
  }
  sort(roots)
  return roots
}

export function treeExcludeSelfAndDescendants<T extends Record<string, unknown>>(
  tree: TreeNode<T>[],
  selfId: unknown,
  idKey: keyof T & string = 'id' as keyof T & string
): TreeNode<T>[] {
  return tree
    .filter((node) => node[idKey] !== selfId)
    .map((node) => ({
      ...node,
      children: node.children?.length
        ? treeExcludeSelfAndDescendants(node.children, selfId, idKey)
        : undefined,
    }))
}
```

---

## 3. List page – Table tree

```tsx
const { data = [], isLoading, error } = useQuery({
  queryKey: ['organizations', { all: true }],
  queryFn: () => organizationsApi.getList({ all: true, includeInactive: true }),
})

const treeData = useMemo(
  () => buildTree(data, { sortBy: (a, b) => (a.displayOrder - b.displayOrder) || (a.code).localeCompare(b.code) }),
  [data]
)

const defaultExpandRowKeys = useMemo(() => treeData.map((n) => n.id), [treeData])

<Table
  rowKey="id"
  bordered
  dataSource={treeData}
  columns={columns}
  loading={isLoading}
  pagination={false}
  defaultExpandRowKeys={defaultExpandRowKeys}
/>
```

---

## 4. Form – TreeSelect for parent

```tsx
const parentTreeData = useMemo(() => {
  const tree = buildTree(data, { sortBy: ... })
  return editingId ? treeExcludeSelfAndDescendants(tree, editingId) : tree
}, [data, editingId])

<Form.Item name="parentId" label="Đơn vị cha">
  <TreeSelect
    allowClear
    placeholder="Không có (gốc)"
    treeData={parentTreeData.map((n) => ({
      value: n.id,
      title: `${n.code} - ${n.name}`,
      children: n.children?.map((c) => ({ value: c.id, title: `${c.code} - ${c.name}`, children: ... })),
    }))}
    showSearch
    filterTreeNode={(input, node) => (node.title ?? '').toString().toLowerCase().includes(input.toLowerCase())}
    treeDefaultExpandAll={false}
  />
</Form.Item>
```

---

## Checklist

- [ ] Backend: List endpoint has `all=true` param; when true returns full flat list.
- [ ] FE: `utils/treeUtils.ts` with buildTree&lt;T&gt;, treeExcludeSelfAndDescendants&lt;T&gt;, TreeNode&lt;T&gt;.
- [ ] List page: useQuery with all=true; useMemo(treeData = buildTree(data)); Table dataSource=treeData, pagination false or showTotal, defaultExpandRowKeys.
- [ ] Form parent: TreeSelect with treeData; when editing use treeExcludeSelfAndDescendants(tree, editingId).
- [ ] Rule: bcdt-hierarchical-data. Doc: [HIERARCHICAL_DATA_BASE_AND_RULE.md](../../../docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md).

---

## Reference

- **Base & rule:** [HIERARCHICAL_DATA_BASE_AND_RULE.md](../../../docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md)
- **Rule:** .cursor/rules/bcdt-hierarchical-data.mdc
- **First implementation (Organization):** [B6_DE_XUAT_TREE_DON_VI.md](../../../docs/de_xuat_trien_khai/B6_DE_XUAT_TREE_DON_VI.md)
- **Agent:** bcdt-hierarchical-data
