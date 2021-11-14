import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class ModelModulePackagesCollection extends BaseCollection {
  records: ModelModulePackage[] = []

  async findAll(slug: string): Promise<ModelModule[]> {
    if (prefetch('model-module-packages')) {
      this.records = prefetch('model-modules-packages')
      return this.records
    }

    const response = await get(`models/${slug}/module-packages`)

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    return this.records
  }
}

export default new ModelModulePackagesCollection()
