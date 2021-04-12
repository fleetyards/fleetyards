import { get, post, put, destroy } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminShopCommoditiesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminShopCommodity[] = []

  params: AdminShopCommodityParams | null = null

  async findAll(
    params: AdminShopCommodityParams | null,
  ): Promise<AdminShopCommodity[]> {
    this.params = params

    const response = await get(`shops/${params!.shopId}/commodities`, {
      q: params?.filters,
      page: params?.page,
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

  async create(
    shopId: string,
    form: AdminShopCommodityForm,
    refetch: boolean = false,
  ): Promise<AdminShopCommodity | null> {
    const response = await post(`shops/${shopId}/commodities`, form)

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }

  async update(
    shopId: string,
    id: string,
    form: AdminShopCommodityForm,
  ): Promise<boolean> {
    const response = await put(`shops/${shopId}/commodities/${id}`, form)
    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async destroy(shopId: string, id: string): Promise<boolean> {
    const response = await destroy(`shops/${shopId}/commodities/${id}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new AdminShopCommoditiesCollection()
