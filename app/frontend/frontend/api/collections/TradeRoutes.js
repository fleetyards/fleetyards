import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class TradeRoutesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('trade-routes', {
      page: params?.page,
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}
export default new TradeRoutesCollection()
