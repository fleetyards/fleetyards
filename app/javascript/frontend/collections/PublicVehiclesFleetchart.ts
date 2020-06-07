import { get } from 'frontend/lib/ApiClient'

export class PublicVehiclesFleetchartCollection {
  records: Vehicle[] = []

  async findAllByUsername(username: string): Promise<Vehicle[]> {
    const response = await get(`vehicles/${username}/fleetchart`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new PublicVehiclesFleetchartCollection()
