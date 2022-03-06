import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class ShopCommoditiesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get(
      `stations/${params?.stationSlug}/shops/${params?.slug}/commodities`,
      {
        page: params.page,
        q: params.filters,
      }
    )

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new ShopCommoditiesCollection()
