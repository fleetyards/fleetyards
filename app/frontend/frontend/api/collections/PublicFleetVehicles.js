import { get } from '@/frontend/api/client'
import Store from '@/frontend/lib/Store'
import BaseCollection from './Base'

export class PublicFleetVehiclesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  stats = null

  get perPage() {
    return Store.getters['publicFleet/perPage']
  }

  get perPageSteps() {
    return [15, 30, 60, 120, 240, 'all']
  }

  updatePerPage(perPage) {
    Store.dispatch('publicFleet/updatePerPage', perPage)
  }

  async findAll(params) {
    const response = await get(`fleets/${params.slug}/public-vehicles`, {
      grouped: params?.grouped,
      page: params?.page,
      perPage: this.perPage,
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(params) {
    const response = await get(`fleets/${params.slug}/public-fleetchart`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findStats(params) {
    const response = await get(`fleets/${params.slug}/quick-stats`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }
}

export default new PublicFleetVehiclesCollection()
