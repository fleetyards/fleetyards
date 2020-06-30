import { get, post, put, destroy, download } from 'frontend/api/client'
import BaseCollection from './Base'

export class VehiclesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Vehicle[] = []

  stats: VehicleStats | null = null

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

  async findAllFleetchart(params: VehicleParams | null): Promise<Vehicle[]> {
    this.params = params

    const response = await get('vehicles/fleetchart', {
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params)
  }

  async findStats(params: VehicleParams): Promise<VehicleStats | null> {
    const response = await get('vehicles/quick-stats', {
      q: params.filters,
    })

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }

  async export(params: VehicleParams): Promise<Vehicle[] | null> {
    const response = await download('vehicles/export', {
      q: params.filters,
    })

    if (!response.error) {
      return response.data
    }

    return null
  }

  async create(
    form: VehicleForm,
    refetch: boolean = false,
  ): Promise<Vehicle | null> {
    const response = await post('vehicles', form)

    if (!response.error) {
      if (refetch) {
        this.findAll(this.params)
      }

      return response.data
    }

    return null
  }

  async update(vehicleId: string, form: VehicleForm): Promise<boolean> {
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

  async destroyAll(): Promise<boolean> {
    const response = await destroy('vehicles/destroy-all')

    if (!response.error) {
      this.findAll(this.params)

      return true
    }

    return false
  }
}

export default new VehiclesCollection()
