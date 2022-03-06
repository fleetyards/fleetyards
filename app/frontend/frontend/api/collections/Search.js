import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class SearchCollection extends BaseCollection {
  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('search', {
      page: params.page,
      q: params.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new SearchCollection()
