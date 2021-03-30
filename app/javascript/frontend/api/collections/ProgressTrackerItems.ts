import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class ProgressTrackerItemsCollection extends BaseCollection {
  records: ProgressTrackerItem[] = []

  params: ProgressTrackerItemParams | null = null

  async findAll(
    params: ProgressTrackerItemParams = {},
  ): Promise<ProgressTrackerItem[]> {
    this.params = params

    const response = await get('progress-tracker-items', params)

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new ProgressTrackerItemsCollection()
