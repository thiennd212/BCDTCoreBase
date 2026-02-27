export interface RoleDto {
  id: number
  code: string
  name: string
  description?: string
  isSystem: boolean
  isActive: boolean
  createdAt: string
}

export interface CreateRoleRequest {
  code: string
  name: string
  description?: string
  isActive: boolean
}

export interface UpdateRoleRequest {
  name: string
  description?: string
  isActive: boolean
}
