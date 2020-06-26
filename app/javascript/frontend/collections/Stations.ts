import { get } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class StationsCollection extends BaseCollection {
  records: Station[] = []

  params: StationParams | null = null

  async findAll(params: StationParams): Promise<Station[]> {
    this.params = params

    const response = await get('stations', {
      q: {
        ...params.filters,
        sorts: ['station_type asc', 'name asc'],
      },
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    this.setPages(response.meta)

    return this.records
  }
}

export default new StationsCollection()
