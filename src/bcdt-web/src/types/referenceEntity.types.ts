export interface ReferenceEntityTypeDto {
  id: number
  code: string
  name: string
  description?: string | null
  isActive: boolean
}

export interface CreateReferenceEntityTypeRequest {
  code: string
  name: string
  description?: string | null
  isActive: boolean
}

export interface UpdateReferenceEntityTypeRequest {
  name: string
  description?: string | null
  isActive: boolean
}

export interface ReferenceEntityDto {
  id: number
  entityTypeId: number
  entityTypeCode?: string | null
  code: string
  name: string
  parentId?: number | null
  parentName?: string | null
  organizationId?: number | null
  displayOrder: number
  isActive: boolean
  validFrom?: string | null
  validTo?: string | null
  createdAt: string
}

export interface CreateReferenceEntityRequest {
  entityTypeId: number
  code: string
  name: string
  parentId?: number | null
  organizationId?: number | null
  displayOrder: number
  isActive: boolean
  validFrom?: string | null
  validTo?: string | null
}

export interface UpdateReferenceEntityRequest {
  name: string
  parentId?: number | null
  organizationId?: number | null
  displayOrder: number
  isActive: boolean
  validFrom?: string | null
  validTo?: string | null
}
