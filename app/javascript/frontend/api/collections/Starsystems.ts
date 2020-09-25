import { get } from 'frontend/api/client'
import { prefetch } from 'frontend/api/prefetch'
import BaseCollection from './Base'

export class StarsystemCollection extends BaseCollection {
  records: Starsystem[] = []

  record: Starsystem | null = null

  params: StarsystemParams | null = null

  async findAll(params: StarsystemParams): Promise<Starsystem[]> {
    if (prefetch('starsystems')) {
      this.records = prefetch('starsystems')
      return this.records
    }

    this.params = params

    const response = await get('starsystems', {
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

export default new StarsystemCollection()
