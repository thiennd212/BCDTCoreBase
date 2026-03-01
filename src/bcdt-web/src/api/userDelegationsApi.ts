import { apiClient } from './apiClient'
import type {
  UserDelegationDto,
  CreateUserDelegationRequest,
  RevokeUserDelegationRequest,
} from '../types/userDelegation.types'

export const userDelegationsApi = {
  getList: async (params?: {
    fromUserId?: number
    toUserId?: number
    activeOnly?: boolean
  }): Promise<UserDelegationDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: UserDelegationDto[] }>(
      '/api/v1/user-delegations',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<UserDelegationDto> => {
    const res = await apiClient.get<{ success: boolean; data: UserDelegationDto }>(
      `/api/v1/user-delegations/${id}`
    )
    return res.data.data
  },

  create: async (body: CreateUserDelegationRequest): Promise<UserDelegationDto> => {
    const res = await apiClient.post<{ success: boolean; data: UserDelegationDto }>(
      '/api/v1/user-delegations',
      body
    )
    return res.data.data
  },

  revoke: async (id: number, body?: RevokeUserDelegationRequest): Promise<UserDelegationDto> => {
    const res = await apiClient.delete<{ success: boolean; data: UserDelegationDto }>(
      `/api/v1/user-delegations/${id}`,
      { data: body }
    )
    return res.data.data
  },
}
