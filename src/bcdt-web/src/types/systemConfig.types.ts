export interface SystemConfigDto {
  id: number
  configKey: string
  configValue: string
  dataType: string
  description?: string
  isEncrypted: boolean
  updatedAt: string
  updatedBy?: number
}

export interface UpdateSystemConfigRequest {
  configValue: string
}
