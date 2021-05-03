import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminEquipmentCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminEquipment[] = []

  params: AdminEquipmentParams | null = null

  async findAll(params: AdminEquipmentParams): Promise<AdminEquipment[]> {
    this.params = params

    const response = await get('equipment', {
      q: params.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new AdminEquipmentCollection()
