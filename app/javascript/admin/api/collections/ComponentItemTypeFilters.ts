import { get } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminComponentItemTypeFiltersCollection extends BaseCollection {
  primaryKey: string = 'value'

  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('components/item_type_filters')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new AdminComponentItemTypeFiltersCollection()
