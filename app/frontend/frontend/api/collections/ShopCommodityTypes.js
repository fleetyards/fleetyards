import { get } from '@/frontend/api/client'

export class ShopCommodityTypesCollection {
  records = []

  async findAll() {
    const response = await get(`shop-commodities/commodity-type-options`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ShopCommodityTypesCollection()
