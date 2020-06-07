import { get } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class ModelsCollection extends BaseCollection {
  records: Model[] = []

  async findAll(params: ModelParams): Promise<Model[]> {
    const response = await get('models', {
      q: params.filters,
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    this.setPages(response.meta)

    return this.records
  }
}

export default new ModelsCollection()
