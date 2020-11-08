import { get, post } from 'frontend/api/client'
import BaseCollection from './Base'

export class CommodityPricesCollection extends BaseCollection {
  primaryKey: string = 'id'

  async create(form: CommodityPriceForm): Promise<CommodityPrice | null> {
    const response = await post('commodity-prices', form)

    if (!response.error) {
      return response.data
    }

    return {
      error: response.error,
    }
  }

  async timeRanges(): Promise<FilterGroupItem[]> {
    const response = await get('commodity-prices/time-ranges')

    if (!response.error) {
      return response.data
    }

    return []
  }
}

export default new CommodityPricesCollection()
