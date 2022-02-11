import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class FleetInvitesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  async findAllForCurrent(identifier = 'default') {
    const response = await get(`fleets/invites`, {
      [identifier]: true,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new FleetInvitesCollection()
