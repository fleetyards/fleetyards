import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class CommoditiesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Commodity[] = []

  params: CommodityParams | null = null

  async findAll(params: CommodityParams): Promise<Commodity[]> {
    this.params = params

    const response = await get('commodities', {
      q: params.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new CommoditiesCollection()
