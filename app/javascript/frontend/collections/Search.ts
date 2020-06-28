import { get } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class SearchCollection extends BaseCollection {
  records: SearchResult[] = []

  params: SearchParams | null = null

  async findAll(params: SearchParams): Promise<SearchResult[]> {
    this.params = params

    const response = await get('search', {
      q: params.filters,
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.loaded = true
    }

    this.setPages(response.meta)

    return this.records
  }
}

export default new SearchCollection()
