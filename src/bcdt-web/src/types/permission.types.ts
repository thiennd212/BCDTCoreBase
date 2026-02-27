export interface PermissionDto {
  id: number
  code: string
  name: string
  module: string
  action: string
  description?: string
  isActive: boolean
}

export interface CreatePermissionRequest {
  code: string
  name: string
  module: string
  action: string
  description?: string
  isActive: boolean
}

export interface UpdatePermissionRequest {
  name: string
  module: string
  action: string
  description?: string
  isActive: boolean
}
