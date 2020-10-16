import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class TradeRoutesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: TradeRoute[] = []

  params: TradeRouteParams | null = null

  async findAll(params: TradeRouteParams | null): Promise<TradeRoute[]> {
    this.params = params

    const response = await get('trade-routes', {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    this.setPages(response.meta)

    return this.records
  }
}
export default new TradeRoutesCollection()
