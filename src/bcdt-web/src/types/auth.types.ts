export interface LoginRequest {
  username: string
  password: string
}

export interface UserInfoDto {
  id: number
  username: string
  email: string
  fullName: string
  isActive?: boolean
}

/** Vai trò của user (dùng cho chuyển vai trò); có thể gắn đơn vị. */
export interface UserRoleItemDto {
  id: number
  code: string
  name: string
  organizationId?: number
  organizationName?: string
}

export interface LoginResponse {
  accessToken: string
  refreshToken: string
  expiresIn: number
  user: UserInfoDto
}

export interface RefreshRequest {
  refreshToken: string
}

export interface RefreshResponse {
  accessToken: string
  expiresIn: number
  refreshToken?: string
  user?: UserInfoDto
}

export interface ApiSuccessResponse<T> {
  success: true
  data: T
}
