import { get } from 'frontend/lib/ApiClient'
import { VehiclesCollection } from 'frontend/collections/Vehicles'

export class VehiclesFleetchartCollection extends VehiclesCollection {
  async findAll(params: VehicleParams | null): Promise<Vehicle[]> {
    this.params = params

    const response = await get('vehicles/fleetchart', {
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new VehiclesFleetchartCollection()
