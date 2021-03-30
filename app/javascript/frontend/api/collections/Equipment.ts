import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class EquipmentCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Equipment[] = []

  params: EquipmentParams | null = null

  async findAll(params: EquipmentParams): Promise<Equipment[]> {
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

export default new EquipmentCollection()
