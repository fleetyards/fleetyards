import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class ShopsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Shop[] = []

  record: Shop | null = null

  params: ShopParams | null = null

  async findAll(params: ShopParams): Promise<Shop[]> {
    this.params = params

    const response = await get('shops', {
      q: params.filters,
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }

  async findBySlugAndStation(params: ShopParams): Promise<Station | null> {
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
