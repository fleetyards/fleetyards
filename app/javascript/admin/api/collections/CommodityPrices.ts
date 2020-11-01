import { get, post, destroy } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminCommodityPricesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: CommodityPrice[] = []

  params: AdminCommodityPriceParams | null = null

  timeRanges = ['1-day', '3-days', '7-days', '30-days']

  async findAll(
    params: AdminCommodityPriceParams | null,
  ): Promise<CommodityPrice[]> {
    this.params = params

    const response = await get(
      `shops/${params?.shopId}/commodities/${params?.shopCommodityId}/${params?.path}-prices`,
      {
        page: params?.page,
      },
    )

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async create(form: AdminCommodityPriceForm): Promise<CommodityPrice | null> {
    // eslint-disable-next-line no-unused-vars, @typescript-eslint/no-unused-vars
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

  async destroy(id: string): Promise<boolean> {
    const response = await destroy(`commodity-prices/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new AdminCommodityPricesCollection()
