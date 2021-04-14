import { get } from 'admin/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminComponentsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminComponent[] = []

  params: AdminComponentParams | null = null

  async findAll(params: AdminComponentParams): Promise<AdminComponent[]> {
    this.params = params

    const response = await get('components', {
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

export default new AdminComponentsCollection()
