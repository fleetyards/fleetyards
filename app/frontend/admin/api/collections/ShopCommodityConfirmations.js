import { get, put, destroy } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class AdminShopCommodityConfirmationsCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('shop-commodities', {
      filters: {
        confirmed: false,
      },
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async refresh() {
    await this.findAll(this.params)
  }

  async confirm(id) {
    const response = await put(`shop-commodities/${id}/confirm`)
    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async destroy(id) {
    const response = await destroy(`shop-commodities/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new AdminShopCommodityConfirmationsCollection()
