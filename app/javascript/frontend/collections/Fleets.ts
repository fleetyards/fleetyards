import { get, post } from 'frontend/lib/ApiClient'
import BaseCollection from './Base'

export class FleetsCollection extends BaseCollection {
  records: Fleet[] = []

  record: Fleet | null = null

  async findBySlug(slug: string): Promise<Fleet | null> {
    const response = await get(`fleets/${slug}`)

    if (!response.error) {
      this.record = response.data
    }

    return this.record
  }

  // tslint:disable-next-line variable-name
  async create(form: FleetForm, _refetch: boolean = false) {
    const response = await post('fleets', form)

    if (!response.error) {
      // if (refetch) {
      //   this.findAll(this.params)
      // }

      return response.data
    }

    return null
  }
}

export default new FleetsCollection()
