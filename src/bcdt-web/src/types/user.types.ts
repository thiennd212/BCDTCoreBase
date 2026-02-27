/** Một cặp (vai trò, đơn vị) – trả về từ API. */
export interface UserRoleOrgItemDto {
  roleId: number
  roleCode: string
  roleName: string
  organizationId?: number
  organizationCode?: string
  organizationName?: string
}

/** Một cặp (vai trò, đơn vị) khi tạo/sửa user. */
export interface UserRoleOrgInputDto {
  roleId: number
  organizationId?: number
}

export interface UserDto {
  id: number
  username: string
  email: string
  fullName: string
  phone?: string
  isActive: boolean
  roleIds: number[]
  organizationIds: number[]
  primaryOrganizationId?: number
  roleOrgAssignments?: UserRoleOrgItemDto[]
}

export interface CreateUserRequest {
  username: string
  password: string
  email: string
  fullName: string
  phone?: string
  isActive: boolean
  roleIds: number[]
  organizationIds: number[]
  primaryOrganizationId?: number
  roleOrgAssignments?: UserRoleOrgInputDto[]
}

export interface UpdateUserRequest {
  email: string
  fullName: string
  phone?: string
  isActive: boolean
  newPassword?: string
  roleIds: number[]
  organizationIds: number[]
  primaryOrganizationId?: number
  roleOrgAssignments?: UserRoleOrgInputDto[]
}
