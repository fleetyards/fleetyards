import { get } from '@/frontend/api/client'
import { prefetch } from '@/frontend/api/prefetch'
import Store from '@/frontend/lib/Store'
import BaseCollection from './Base'

export class ModelsCollection extends BaseCollection {
  records = []

  record = null

  params = null

  get perPage() {
    return Store.getters['models/perPage']
  }

  get perPageSteps() {
    return [15, 30, 60, 120, 240]
  }

  updatePerPage(perPage) {
    Store.dispatch('models/updatePerPage', perPage)
  }

  async findAll(params) {
    if (prefetch('models')) {
      this.records = prefetch('models')
      return this.records
    }

    this.params = params

    const response = await get('models', {
      page: params.page,
      perPage: this.perPage,
      q: params.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(options) {
    const response = await get('models/fleetchart', {
      q: options.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findBySlug(slug) {
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

  async latest() {
    const response = await get('models/latest')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ModelsCollection()
