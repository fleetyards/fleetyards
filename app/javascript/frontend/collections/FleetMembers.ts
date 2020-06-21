import { get } from 'frontend/lib/ApiClient'

export class FleetMembersCollection {
  records: FleetMember[] = []

  stats: FleetMemberStats | null = null

  async findAll(params: FleetMembersParams): Promise<FleetMember[]> {
    const response = await get(`fleets/${params.slug}/members`, {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async findStats(
    params: FleetMembersParams,
  ): Promise<FleetMemberStats | null> {
    const response = await get(`fleets/${params.slug}/member-quick-stats`, {
      q: params?.filters,
    })

    if (!response.error) {
      this.stats = response.data
    }

    return this.stats
  }
}

export default new FleetMembersCollection()
