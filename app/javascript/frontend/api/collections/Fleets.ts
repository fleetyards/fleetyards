import { get, post } from 'frontend/api/client'
import BaseCollection from './Base'

export class FleetsCollection extends BaseCollection {
  records: Fleet[] = []

  record: Fleet | null = null

  async findAllForCurrent(identifier: string = 'default'): Promise<Fleet[]> {
    const response = await get(`fleets/current`, {
      [identifier]: true,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

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

  async findModelsByClassificationBySlug(slug: string): Promise<ChartData[]> {
    const response = await get(`fleets/${slug}/stats/models-by-classification`)

    if (!response.error) {
      return response.data
    }

    return []
  }

  async findModelsBySizeBySlug(slug: string): Promise<ChartData[]> {
    const response = await get(`fleets/${slug}/stats/models-by-size`)

    if (!response.error) {
      return response.data
    }

    return []
  }

  async findModelsByManufacturerBySlug(slug: string): Promise<ChartData[]> {
    const response = await get(`fleets/${slug}/stats/models-by-manufacturer`)

    if (!response.error) {
      return response.data
    }

    return []
  }

  async findModelsByProductionStatusBySlug(slug: string): Promise<ChartData[]> {
    const response = await get(
      `fleets/${slug}/stats/models-by-production-status`,
    )

    if (!response.error) {
      return response.data
    }

    return []
  }
}

export default new FleetsCollection()
