import { get, post, put, destroy } from 'frontend/api/client'
import BaseCollection from './Base'

export class HangarGroupsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: HangarGroup[] = []

  async findAll(): Promise<HangarGroup[]> {
    const response = await get('hangar-groups')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async create(
    form: HangarGroupForm,
    refetch: boolean = false,
  ): Promise<HangarGroup | null> {
    const response = await post('hangar-groups', form)

    if (!response.error) {
      if (refetch) {
        this.findAll()
      }

      return response.data
    }

    return null
  }

  async update(hangarGroupId: string, form: HangarGroupForm): Promise<boolean> {
    const response = await put(`hangar-groups/${hangarGroupId}`, form)
    if (!response.error) {
      this.findAll()

      return true
    }

    return false
  }

  async destroy(hangarGroupId: string): Promise<boolean> {
    const response = await destroy(`hangar-groups/${hangarGroupId}`)

    if (!response.error) {
      this.findAll()

      return true
    }

    return false
  }
}

export default new HangarGroupsCollection()
