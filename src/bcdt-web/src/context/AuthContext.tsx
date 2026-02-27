import React, { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { tokenStore, getStoredCurrentRole, setStoredCurrentRole, clearStoredCurrentRole } from '../api/apiClient'
import { authApi } from '../api/authApi'
import type { UserInfoDto, UserRoleItemDto } from '../types/auth.types'

interface AuthState {
  token: string | null
  user: UserInfoDto | null
  loading: boolean
  currentRole: UserRoleItemDto | null
}

interface AuthContextValue extends AuthState {
  login: (username: string, password: string) => Promise<void>
  logout: () => void | Promise<void>
  setCurrentRole: (role: UserRoleItemDto | null) => void
  isAuthenticated: boolean
}

const AuthContext = createContext<AuthContextValue | null>(null)

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<AuthState>({
    token: tokenStore.get(),
    user: null,
    loading: true,
    currentRole: getStoredCurrentRole(),
  })

  const setCurrentRole = useCallback((role: UserRoleItemDto | null) => {
    if (role) setStoredCurrentRole(role)
    else clearStoredCurrentRole()
    setState((prev) => ({ ...prev, currentRole: role }))
  }, [])

  const loadUser = useCallback(async () => {
    const storedRole = getStoredCurrentRole()
    try {
      const user = await authApi.me()
      const token = tokenStore.get()
      setState((prev) => ({ ...prev, token, user, loading: false, currentRole: storedRole ?? prev.currentRole }))
      // Đăng nhập lần đầu hoặc chưa có vai trò lưu: lấy danh sách vai trò và chọn vai trò đầu tiên
      if (!storedRole) {
        const roles = await authApi.getMyRoles()
        if (roles.length > 0) setCurrentRole(roles[0])
      }
    } catch {
      setState({ token: null, user: null, loading: false, currentRole: storedRole })
    }
  }, [setCurrentRole])

  useEffect(() => {
    loadUser()
  }, [loadUser])

  const login = useCallback(async (username: string, password: string) => {
    const data = await authApi.login({ username, password })
    setState((prev) => ({ ...prev, token: data.accessToken, user: data.user, loading: false }))
    // Sau đăng nhập: lấy danh sách vai trò và tự chọn vai trò đầu tiên để không thiếu vai trò
    const roles = await authApi.getMyRoles()
    if (roles.length > 0) setCurrentRole(roles[0])
  }, [setCurrentRole])

  const logout = useCallback(async () => {
    try {
      await authApi.logout()
    } finally {
      tokenStore.clear()
      clearStoredCurrentRole()
      setState({ token: null, user: null, loading: false, currentRole: null })
    }
  }, [])

  const value: AuthContextValue = {
    ...state,
    login,
    logout,
    setCurrentRole,
    isAuthenticated: !!state.token,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) throw new Error('useAuth must be used within AuthProvider')
  return ctx
}
