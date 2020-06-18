import { get } from 'frontend/lib/ApiClient'

export class FleetModelsCollection {
  records: Model[] = []

  async findAll(params: FleetModelsParams): Promise<Model[]> {
    const response = await get(`fleets/${params.slug}/models`, {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new FleetModelsCollection()
