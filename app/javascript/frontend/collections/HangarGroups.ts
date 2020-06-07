import { get } from 'frontend/lib/ApiClient'

export class HangarGroupsCollection {
  records: HangarGroup[] = []

  async findAll(): Promise<HangarGroup[]> {
    const response = await get('hangar-groups')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new HangarGroupsCollection()
