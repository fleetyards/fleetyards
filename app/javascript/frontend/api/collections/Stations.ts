import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class StationsCollection extends BaseCollection {
  records: Station[] = []

  record: Station | null = null

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
      this.setPages(response.meta)
    }

    return this.records
  }

  async findBySlug(slug: string): Promise<Station | null> {
    if (prefetch('station')) {
      this.record = prefetch('station')
      return this.record
    }

    const response = await get(`stations/${slug}`)

    if (!response.errors) {
      this.record = response.data
    }

    return this.record
  }
}

export default new StationsCollection()
