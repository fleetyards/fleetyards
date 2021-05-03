import { get, put, destroy } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminCommodityPriceConfirmationsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminCommodityPrice[] = []

  params: AdminCommodityPriceParams | null = null

  async findAll(
    params: AdminCommodityPriceParams | null,
  ): Promise<AdminCommodityPrice[]> {
    this.params = params

    const response = await get('commodity-prices', {
      page: params?.page,
      q: {
        confirmedEq: false,
      },
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params)
  }

  async confirm(id: string): Promise<boolean> {
    const response = await put(`commodity-prices/${id}/confirm`)
    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async destroy(id: string): Promise<boolean> {
    const response = await destroy(`commodity-prices/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new AdminCommodityPriceConfirmationsCollection()
