/**
 * Utils cho dữ liệu phân cấp (Hierarchical Data) – BCDT.
 * Theo HIERARCHICAL_DATA_BASE_AND_RULE.md: buildTree<T>, treeExcludeSelfAndDescendants<T>.
 */

export type TreeNode<T> = T & { children?: TreeNode<T>[] }

export interface BuildTreeOptions<T> {
  idKey?: keyof T & string
  parentKey?: keyof T & string
  childrenKey?: keyof T & string
  sortBy?: (a: T, b: T) => number
}

/**
 * Chuyển danh sách phẳng thành cây (O(n)).
 * parentId null/undefined = gốc; nếu parent không tồn tại thì đẩy node xuống gốc (phòng thủ).
 */
export function buildTree<T extends object>(
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
      if (parent && Array.isArray(parent[childrenKey])) {
        (parent[childrenKey] as TreeNode<T>[]).push(node)
      } else {
        roots.push(node)
      }
    }
  }

  const sortNodes = (nodes: TreeNode<T>[]) => {
    if (sortBy) nodes.sort((a, b) => sortBy(a, b))
    nodes.forEach((n) => {
      const children = n[childrenKey] as TreeNode<T>[] | undefined
      if (children?.length) sortNodes(children)
    })
  }
  sortNodes(roots)
  return roots
}

/**
 * Loại bỏ node có id === selfId và toàn bộ con (descendants). Dùng cho TreeSelect khi sửa (tránh chọn chính mình hoặc con làm cha).
 */
export function treeExcludeSelfAndDescendants<T extends object>(
  tree: TreeNode<T>[],
  selfId: unknown,
  idKey: keyof T & string = 'id' as keyof T & string
): TreeNode<T>[] {
  return tree
    .filter((node) => node[idKey] !== selfId)
    .map((node) => ({
      ...node,
      children: (node.children?.length
        ? treeExcludeSelfAndDescendants(node.children, selfId, idKey)
        : undefined) as TreeNode<T>[] | undefined,
    }))
}
