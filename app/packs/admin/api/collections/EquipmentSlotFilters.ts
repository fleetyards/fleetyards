import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminEquipmentSlotFiltersCollection extends BaseCollection {
  primaryKey: string = 'value'

  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('equipment/slot_filters')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new AdminEquipmentSlotFiltersCollection()
