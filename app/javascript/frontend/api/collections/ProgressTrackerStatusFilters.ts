import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class ProgressTrackerStatusFiltersCollection extends BaseCollection {
  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get('progress-tracker-items/team-filters')

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    return this.records
  }
}

export default new ProgressTrackerStatusFiltersCollection()
