import { get, put, destroy } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class VehiclesCollection extends BaseCollection {
  records: Vehicle[] = []

  params: VehicleParams | null = null

  async findAll(params: VehicleParams | null): Promise<Vehicle[]> {
    this.params = params

    const response = await get('vehicles', {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    this.setPages(response.meta)

    return this.records
  }

  async save(vehicleId: string, form: Vehicle): Promise<boolean> {
    const response = await put(`vehicles/${vehicleId}`, form)
    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }

  async destroy(vehicleId: string): Promise<boolean> {
    const response = await destroy(`vehicles/${vehicleId}`)

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new VehiclesCollection()
