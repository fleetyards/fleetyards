import { get } from 'frontend/api/client'

export class ShopCommodityTypesCollection {
  records: FilterGroupItem[] = []

  async findAll(): Promise<FilterGroupItem[]> {
    const response = await get(`shop-commodities/commodity-type-options`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ShopCommodityTypesCollection()
