import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class ModelPaintsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: ModelPaint[] = []

  params: ModelPaintParams | null = null

  async findAll(params: ModelPaintParams): Promise<ModelPaint[]> {
    this.params = params

    const response = await get('model-paints', {
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

export default new ModelPaintsCollection()
