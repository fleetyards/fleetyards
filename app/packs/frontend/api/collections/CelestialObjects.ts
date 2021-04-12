import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class CelestialObjectCollection extends BaseCollection {
  records: CelestialObject[] = []

  record: CelestialObject | null = null

  params: CelestialObjectParams | null = null

  async findAll(params: CelestialObjectParams): Promise<CelestialObject[]> {
    if (prefetch('celestialObjects')) {
      this.records = prefetch('celestialObjects')
      return this.records
    }

    this.params = params

    const response = await get('celestial-objects', {
      q: params.filters,
      page: params.page,
      cacheId: params.cacheId,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new CelestialObjectCollection()
