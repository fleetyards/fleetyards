import { get, post, destroy } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class AdminCommodityPricesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get(
      `shops/${params?.shopId}/commodities/${params?.shopCommodityId}/${params?.path}-prices`,
      {
        page: params?.page,
      }
    )

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async create(form) {
    const { path, ...cleanForm } = form

    const response = await post(`commodity-prices/create-${path}-price`, {
      ...cleanForm,
    })

    if (!response.error) {
      this.findAll(this.params)

      return response.data
    }

    return null
  }

  async destroy(id) {
    const response = await destroy(`commodity-prices/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async timeRanges() {
    const response = await get('commodity-prices/time-ranges')

    if (!response.error) {
      return response.data
    }

    return []
  }
}

export default new AdminCommodityPricesCollection()
