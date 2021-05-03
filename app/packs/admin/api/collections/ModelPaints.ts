import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminModelPaintsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminModelPaint[] = []

  params: AdminModelPaintParams | null = null

  async findAll(params: AdminModelPaintParams): Promise<AdminModelPaint[]> {
    this.params = params

    const response = await get('model-paints', {
      q: params.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new AdminModelPaintsCollection()
