import { get } from 'frontend/lib/ApiClient'

export class FleetMembersCollection {
  records: FleetMember[] = []

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
}

export default new FleetMembersCollection()
