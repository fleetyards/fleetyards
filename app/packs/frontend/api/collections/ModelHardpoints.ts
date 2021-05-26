import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class ModelHardpointsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: ModelHardpoint[] = []

  async findAllByModel(modelSlug: string): Promise<ModelHardpoint[]> {
    const response = await get(`models/${modelSlug}/hardpoints`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ModelHardpointsCollection()
