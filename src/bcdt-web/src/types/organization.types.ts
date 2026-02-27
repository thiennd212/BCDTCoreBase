export interface OrganizationDto {
  id: number
  code: string
  name: string
  shortName?: string
  organizationTypeId: number
  organizationTypeCode?: string
  parentId?: number
  treePath: string
  level: number
  address?: string
  phone?: string
  email?: string
  taxCode?: string
  isActive: boolean
  displayOrder: number
}

export interface CreateOrganizationRequest {
  code: string
  name: string
  shortName?: string
  organizationTypeId: number
  parentId?: number
  address?: string
  phone?: string
  email?: string
  taxCode?: string
  isActive: boolean
  displayOrder: number
}

export interface UpdateOrganizationRequest extends CreateOrganizationRequest {}

// ---- OrganizationType ----
export interface OrganizationTypeDto {
  id: number
  code: string
  name: string
  level: number
  parentTypeId?: number
  description?: string
  isActive: boolean
  organizationCount: number
}

export interface CreateOrganizationTypeRequest {
  code: string
  name: string
  level: number
  parentTypeId?: number
  description?: string
  isActive: boolean
}

export interface UpdateOrganizationTypeRequest {
  name: string
  level: number
  parentTypeId?: number
  description?: string
  isActive: boolean
}
