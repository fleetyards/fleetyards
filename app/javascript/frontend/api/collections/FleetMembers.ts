import { get } from 'frontend/api/client'

export class FleetMembersCollection {
  records: FleetMember[] = []

  record: FleetMember | null = null

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

  async findByFleet(slug: string): Promise<FleetMember | null> {
    const response = await get(`fleets/${slug}/members/current`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new FleetMembersCollection()
