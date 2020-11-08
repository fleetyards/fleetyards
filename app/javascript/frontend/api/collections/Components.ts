import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class ComponentsCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Component[] = []

  params: ComponentParams | null = null

  async findAll(params: ComponentParams): Promise<Component[]> {
    this.params = params

    const response = await get('components', {
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

export default new ComponentsCollection()
