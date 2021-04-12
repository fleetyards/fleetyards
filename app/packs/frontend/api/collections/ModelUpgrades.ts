import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class ModelUpgradesCollection extends BaseCollection {
  records: ModelUpgrade[] = []

  async findAll(slug: string): Promise<ModelUpgrade[]> {
    if (prefetch('model-modules')) {
      this.records = prefetch('model-modules')
      return this.records
    }

    const response = await get(`models/${slug}/upgrades`)

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    return this.records
  }
}

export default new ModelUpgradesCollection()
