import { get } from 'frontend/api/client'

export class HangarItemsCollection {
  records: string[] = []

  async findAll(): Promise<string[]> {
    const response = await get('vehicles/hangar-items', {}, true)

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new HangarItemsCollection()
