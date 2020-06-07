import { get } from 'frontend/lib/ApiClient'

export class PublicHangarStatsCollection {
  record: PublicHangarStats | null = null

  async findByUsername(username: string): Promise<PublicHangarStats | null> {
    const response = await get(`vehicles/${username}/quick-stats`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }
}

export default new PublicHangarStatsCollection()
