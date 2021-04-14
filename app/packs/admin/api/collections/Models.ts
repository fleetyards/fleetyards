import { get } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminModelsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminModel[] = []

  params: AdminAdminModelParams | null = null

  async findAll(params: AdminAdminModelParams): Promise<AdminModel[]> {
    this.params = params

    const response = await get('models', {
      q: params.filters,
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new AdminModelsCollection()
