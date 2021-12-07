import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import Store from 'frontend/lib/Store'
import BaseCollection from './Base'

export class ModelsCollection extends BaseCollection {
  records: Model[] = []

  record: Model | null = null

  params: ModelParams | null = null

  get perPage(): number {
    return Store.getters['models/perPage']
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240]
  }

  updatePerPage(perPage) {
    Store.dispatch('models/updatePerPage', perPage)
  }

  async findAll(params: ModelParams): Promise<Model[]> {
    if (prefetch('models')) {
      this.records = prefetch('models')
      return this.records
    }

    this.params = params

    const response = await get('models', {
      q: params.filters,
      page: params.page,
      perPage: this.perPage,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(options: ModelParams): Promise<Model[]> {
    const response = await get('models/fleetchart', {
      q: options.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findBySlug(slug: string): Promise<Model | null> {
    if (prefetch('model')) {
      this.record = prefetch('model')
      return this.record
    }

    const response = await get(`models/${slug}`)

    if (!response.error) {
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
