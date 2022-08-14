import { get } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class AdminEquipmentItemTypeFiltersCollection extends BaseCollection {
  primaryKey = 'value'

  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('equipment/item_type_filters')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new AdminEquipmentItemTypeFiltersCollection()
