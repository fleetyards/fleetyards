import { get, post, put, destroy } from '@/frontend/api/client'
import BaseCollection from './Base'

export class HangarGroupsCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  async findAll() {
    const response = await get('hangar-groups')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }

  async create(form, refetch = false) {
    const response = await post('hangar-groups', form)

    if (!response.error) {
      if (refetch) {
        this.findAll()
      }

      return response.data
    }

    return null
  }

  async update(hangarGroupId, form) {
    const response = await put(`hangar-groups/${hangarGroupId}`, form)
    if (!response.error) {
      this.findAll()

      return true
    }

    return false
  }

  async destroy(hangarGroupId) {
    const response = await destroy(`hangar-groups/${hangarGroupId}`)

    if (!response.error) {
      this.findAll()

      return true
    }

    return false
  }
}

export default new HangarGroupsCollection()
