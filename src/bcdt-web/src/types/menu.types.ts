export interface MenuDto {
  id: number
  code: string
  name: string
  parentId?: number | null
  parentName?: string | null
  url?: string | null
  icon?: string | null
  displayOrder: number
  isVisible: boolean
  requiredPermission?: string | null
  createdAt: string
  children?: MenuDto[]
}

export interface CreateMenuRequest {
  code: string
  name: string
  parentId?: number | null
  url?: string | null
  icon?: string | null
  displayOrder: number
  isVisible: boolean
  requiredPermission?: string | null
}

export interface UpdateMenuRequest {
  name: string
  parentId?: number | null
  url?: string | null
  icon?: string | null
  displayOrder: number
  isVisible: boolean
  requiredPermission?: string | null
}
