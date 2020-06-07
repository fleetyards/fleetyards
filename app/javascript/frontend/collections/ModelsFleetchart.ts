import { get } from 'frontend/lib/ApiClient'

export class ModelsFleetchartCollection {
  records: Model[] = []

  async findAll(options: ModelParams): Promise<Model[]> {
    const response = await get('models/fleetchart', {
      q: options.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ModelsFleetchartCollection()
