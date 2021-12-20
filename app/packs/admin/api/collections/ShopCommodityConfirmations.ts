import { get, put, destroy } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminShopCommodityConfirmationsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminShopCommodity[] = []

  params: AdminShopCommodityParams | null = null

  async findAll(
    params: AdminShopCommodityParams | null
  ): Promise<AdminShopCommodity[]> {
    this.params = params

    const response = await get('shop-commodities', {
      page: params?.page,
      filters: {
        confirmed: false,
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
    const response = await put(`shop-commodities/${id}/confirm`)
    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async destroy(id: string): Promise<boolean> {
    const response = await destroy(`shop-commodities/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new AdminShopCommodityConfirmationsCollection()
