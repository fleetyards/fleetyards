import { get } from 'frontend/lib/ApiClient'

export class FleetMemberStatsCollection {
  record: FleetMemberStats | null = null

  async findAll(params: FleetMembersParams): Promise<FleetMemberStats | null> {
    const response = await get(`fleets/${params.slug}/member-quick-stats`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new FleetMemberStatsCollection()
