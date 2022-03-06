import { get } from '@/frontend/api/client'
import { prefetch } from '@/frontend/api/prefetch'
import BaseCollection from './Base'

export class CelestialObjectCollection extends BaseCollection {
  records = []

  record = null

  params = null

  async findAll(params) {
    if (prefetch('celestialObjects')) {
      this.records = prefetch('celestialObjects')
      return this.records
    }

    this.params = params

    const response = await get('celestial-objects', {
      cacheId: params.cacheId,
      page: params.page,
      q: params.filters,
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
