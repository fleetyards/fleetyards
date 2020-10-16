import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class PublicVehiclesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Vehicle[] = []

  stats: PublicVehicleStats | null = null

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

  async findAllFleetchartByUsername(username: string): Promise<Vehicle[]> {
    const response = await get(`vehicles/${username}/fleetchart`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async refresh(): Promise<void> {
    if (!this.username) {
      return
    }

    await this.findAllByUsername(this.username, this.params)
  }

  async findStatsByUsername(
    username: string,
  ): Promise<PublicVehicleStats | null> {
    const response = await get(`vehicles/${username}/quick-stats`)

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }
}

export default new PublicVehiclesCollection()
