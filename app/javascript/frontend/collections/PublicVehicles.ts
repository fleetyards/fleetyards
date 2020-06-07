import { get } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class PublicVehiclesCollection extends BaseCollection {
  records: Vehicle[] = []

  params: VehicleParams | null = null

  username: string | null = null

  async findAllByUsername(
    username: string,
    params: VehicleParams | null,
  ): Promise<Vehicle[]> {
    this.params = params
    this.username = username

    const response = await get(`vehicles/${username}`, {
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    this.setPages(response.meta)

    return this.records
  }

  async refresh(): Promise<void> {
    if (!this.username) {
      return
    }

    await this.findAllByUsername(this.username, this.params)
  }
}

export default new PublicVehiclesCollection()
