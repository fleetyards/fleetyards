import { get } from '@/frontend/api/client'
import Store from '@/frontend/lib/Store'
import BaseCollection from './Base'

export class PublicVehiclesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  stats = null

  params = null

  username = null

  get perPage() {
    return Store.getters['publicHangar/perPage']
  }

  get perPageSteps() {
    return [15, 30, 60, 120, 240, 'all']
  }

  updatePerPage(perPage) {
    Store.dispatch('publicHangar/updatePerPage', perPage)
  }

  async findAll(params) {
    if (!params?.username) {
      return []
    }

    this.params = params

    const response = await get(`vehicles/${params?.username}`, {
      q: params?.filters,
      page: params?.page,
      perPage: this.perPage,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(params) {
    if (!params?.username) {
      return []
    }

    this.params = params

    const response = await get(`vehicles/${params?.username}/fleetchart`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async refresh() {
    await this.findAll(this.params)
  }

  async findStatsByUsername(username, params) {
    const response = await get(`vehicles/${username}/quick-stats`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }
}

export default new PublicVehiclesCollection()
