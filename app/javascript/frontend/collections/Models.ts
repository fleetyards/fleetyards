import { get } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class ModelsCollection extends BaseCollection {
  records: Model[] = []

  record: Model | null = null

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

  async findBySlug(slug: string): Promise<Model | null> {
    const response = await get(`models/${slug}`)

    if (!response.errors) {
      this.record = response.data
    }

    return this.record
  }

  async latest(): Promise<Model[]> {
    const response = await get('models/latest')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ModelsCollection()
