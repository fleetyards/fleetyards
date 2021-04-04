import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class FleetInviteUrlsCollection extends BaseCollection {
  primaryKey: string = 'token'

  records: FleetInviteUrl[] = []

  async findAll(fleetSlug: string): Promise<FleetInviteUrl[]> {
    const response = await get(`fleets/${fleetSlug}/invite-urls/`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async checkToken(fleetSlug: string, token: string): Promise<boolean> {
    const response = await get(
      `fleets/${fleetSlug}/invite-urls/${token}/exists`,
    )

    if (!response.error) {
      return true
    }

    return false
  }

  async findByToken(
    fleetSlug: string,
    token: string,
  ): Promise<FleetInviteUrl | null> {
    const response = await get(`fleets/${fleetSlug}/invite-urls/${token}`)

    if (!response.error) {
      return response.data
    }

    return null
  }
}

export default new FleetInviteUrlsCollection()
