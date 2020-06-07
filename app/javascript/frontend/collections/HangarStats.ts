import { get } from 'frontend/lib/ApiClient'

export class HangarStatsCollection {
  record: HangarStats | null = null

  async current(params: VehicleParams): Promise<HangarStats | null> {
    const response = await get('vehicles/quick-stats', {
      q: params.filters,
    })

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new HangarStatsCollection()
