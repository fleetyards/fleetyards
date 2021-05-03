import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminModelModulesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminModelModule[] = []

  params: AdminModelModuleParams | null = null

  async findAll(params: AdminModelModuleParams): Promise<AdminModelModule[]> {
    this.params = params

    const response = await get('model-modules', {
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

export default new AdminModelModulesCollection()
