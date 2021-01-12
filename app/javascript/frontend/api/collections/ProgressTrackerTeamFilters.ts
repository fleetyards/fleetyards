import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class ProgressTrackerItemsCollection extends BaseCollection {
  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('progress-tracker-items/status-filters')

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    return this.records
  }
}

export default new ProgressTrackerItemsCollection()
