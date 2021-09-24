import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class PublicHangarGroupsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: HangarGroup[] = []

  async findAll(): Promise<HangarGroup[]> {
    const response = await get('hangar-groups/public')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new PublicHangarGroupsCollection()
