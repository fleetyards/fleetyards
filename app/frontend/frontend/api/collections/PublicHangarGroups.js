import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class PublicHangarGroupsCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  async findAll(username) {
    const response = await get(`hangar-groups/${username}`)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new PublicHangarGroupsCollection()
