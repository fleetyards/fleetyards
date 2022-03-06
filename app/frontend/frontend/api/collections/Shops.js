import { get } from '@/frontend/api/client'
import { prefetch } from '@/frontend/api/prefetch'
import BaseCollection from './Base'

export class ShopsCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  record = null

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('shops', {
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

  async findBySlugAndStation(params) {
    if (prefetch('shop')) {
      this.record = prefetch('shop')
      return this.record
    }

    const response = await get(
      `stations/${params?.stationSlug}/shops/${params?.slug}`
    )

    if (!response.errors) {
      this.record = response.data
    }

    return this.record
  }
}

export default new ShopsCollection()
