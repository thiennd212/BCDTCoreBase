import React, { createContext, useCallback, useContext, useMemo } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useAuth } from './AuthContext'
import { rolesApi } from '../api/rolesApi'

interface RolePermissionsContextValue {
  /** Danh sách ID quyền của vai trò hiện tại */
  permissionIds: number[]
  /** Kiểm tra vai trò hiện tại có quyền theo ID */
  hasPermission: (permissionId: number) => boolean
  isLoading: boolean
}

const RolePermissionsContext = createContext<RolePermissionsContextValue | null>(null)

export function RolePermissionsProvider({ children }: { children: React.ReactNode }) {
  const { currentRole } = useAuth()
  const { data: permissionIds = [], isLoading } = useQuery({
    queryKey: ['role-permissions', currentRole?.id ?? null],
    queryFn: () => (currentRole ? rolesApi.getPermissions(currentRole.id) : Promise.resolve([])),
    enabled: !!currentRole?.id,
    staleTime: 2 * 60 * 1000,
  })

  const hasPermission = useCallback(
    (permissionId: number) => permissionIds.includes(permissionId),
    [permissionIds]
  )

  const value = useMemo<RolePermissionsContextValue>(
    () => ({ permissionIds, hasPermission, isLoading }),
    [permissionIds, hasPermission, isLoading]
  )

  return (
    <RolePermissionsContext.Provider value={value}>
      {children}
    </RolePermissionsContext.Provider>
  )
}

export function useRolePermissions(): RolePermissionsContextValue {
  const ctx = useContext(RolePermissionsContext)
  if (!ctx) throw new Error('useRolePermissions must be used within RolePermissionsProvider')
  return ctx
}
