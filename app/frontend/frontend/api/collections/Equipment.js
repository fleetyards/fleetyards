import { get } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class EquipmentCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('equipment', {
      page: params?.page,
      q: params.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new EquipmentCollection()
