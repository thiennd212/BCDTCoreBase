export interface UserDelegationDto {
  id: number
  fromUserId: number
  fromUserName?: string | null
  toUserId: number
  toUserName?: string | null
  /** 'Full' | 'Partial' */
  delegationType: string
  /** JSON array permission codes (khi Partial) */
  permissions?: string | null
  organizationId?: number | null
  reason?: string | null
  validFrom: string
  validTo: string
  isActive: boolean
  createdAt: string
  createdBy: number
  revokedAt?: string | null
  revokedBy?: number | null
  revokedReason?: string | null
}

export interface CreateUserDelegationRequest {
  fromUserId: number
  toUserId: number
  delegationType: string
  permissions?: string | null
  organizationId?: number | null
  reason?: string | null
  validFrom: string
  validTo: string
}

export interface RevokeUserDelegationRequest {
  revokedReason?: string | null
}
