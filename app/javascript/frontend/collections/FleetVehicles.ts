import { get } from 'frontend/lib/ApiClient'

export class FleetVehiclesCollection {
  records: Vehicle[] = []

  async findAll(params: FleetVehicleParams): Promise<Vehicle[]> {
    const response = await get(`fleets/${params.slug}/vehicles`, {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new FleetVehiclesCollection()
