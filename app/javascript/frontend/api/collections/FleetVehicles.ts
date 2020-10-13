import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class FleetVehiclesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: (Vehicle | Model)[] = []

  stats: FleetVehicleStats | null = null

  async findAll(params: FleetVehicleParams): Promise<(Vehicle | Model)[]> {
    const response = await get(`fleets/${params.slug}/vehicles`, {
      q: params?.filters,
      page: params?.page,
      grouped: params?.grouped,
    })

    if (!response.error) {
      this.records = response.data
    }

    this.setPages(response.meta)

    return this.records
  }

  async findAllFleetchart(
    params: FleetVehicleParams,
  ): Promise<(Vehicle | Model)[]> {
    const response = await get(`fleets/${params.slug}/fleetchart`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findStats(
    params: FleetVehicleParams,
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

export default new FleetVehiclesCollection()
