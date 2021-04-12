import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class ShopCommoditiesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: ShopCommodity[] = []

  params: ShopCommodityParams | null = null

  async findAll(params: ShopCommodityParams): Promise<ShopCommodity[]> {
    this.params = params

    const response = await get(
      `stations/${params?.stationSlug}/shops/${params?.slug}/commodities`,
      {
        q: params.filters,
        page: params.page,
      },
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
