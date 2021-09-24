import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class PublicVehiclesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Vehicle[] = []

  stats: PublicVehicleStats | null = null

  params: PublicVehicleParams | null = null

  username: string | null = null

  async findAll(params: PublicVehicleParams | null): Promise<Vehicle[]> {
    if (!params?.username) {
      return []
    }

    this.params = params

    const response = await get(`vehicles/${params?.username}`, {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllFleetchart(
    params: PublicVehicleParams | null,
  ): Promise<Vehicle[]> {
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

  async refresh(): Promise<void> {
    await this.findAll(this.params)
  }

  async findStatsByUsername(
    username: string,
    params: PublicVehicleParams | null,
  ): Promise<PublicVehicleStats | null> {
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
