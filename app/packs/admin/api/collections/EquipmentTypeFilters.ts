import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminEquipmentTypeFiltersCollection extends BaseCollection {
  primaryKey: string = 'value'

  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('equipment/type_filters')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new AdminEquipmentTypeFiltersCollection()
