import { get } from '@/frontend/api/client'
import { prefetch } from '@/frontend/api/prefetch'
import BaseCollection from './Base'

export class StationsCollection extends BaseCollection {
  records = []

  record = null

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('stations', {
      page: params.page,
      q: {
        ...params.filters,
        sorts: ['station_type asc', 'name asc'],
      },
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }

  async findBySlug(slug) {
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
