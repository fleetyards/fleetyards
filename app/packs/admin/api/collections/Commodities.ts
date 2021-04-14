import { get } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminCommoditiesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminCommodity[] = []

  params: AdminCommodityParams | null = null

  async findAll(params: AdminCommodityParams): Promise<AdminCommodity[]> {
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

export default new AdminCommoditiesCollection()
