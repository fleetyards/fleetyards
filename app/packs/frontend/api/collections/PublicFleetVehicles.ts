import { get } from 'frontend/api/client'
import Store from 'frontend/lib/Store'
import BaseCollection from './Base'

export class PublicFleetVehiclesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: (Vehicle | Model)[] = []

  stats: FleetVehicleStats | null = null

  get perPage(): number | string {
    return Store.getters['publicFleet/perPage']
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, 'all']
  }

  updatePerPage(perPage) {
    Store.dispatch('publicFleet/updatePerPage', perPage)
  }

  async findAll(params: FleetVehicleParams): Promise<(Vehicle | Model)[]> {
    const response = await get(`fleets/${params.slug}/public-vehicles`, {
      q: params?.filters,
      page: params?.page,
      grouped: params?.grouped,
      perPage: this.perPage,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(
    params: FleetVehicleParams
  ): Promise<(Vehicle | Model)[]> {
    const response = await get(`fleets/${params.slug}/public-fleetchart`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findStats(
    params: FleetVehicleParams
  ): Promise<FleetVehicleStats | null> {
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
