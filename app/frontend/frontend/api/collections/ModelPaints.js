import { get } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class ModelPaintsCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('model-paints', {
      page: params?.page,
      q: params.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllByModel(modelSlug) {
    const response = await get(`models/${modelSlug}/paints`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ModelPaintsCollection()
