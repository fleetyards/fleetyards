import { get } from '@/frontend/api/client'
import BaseCollection from '@/frontend/api/collections/Base'

export class AdminImagesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  params = null

  async findAll(params) {
    this.params = params

    const response = await get('images', {
      page: params?.page,
      q: params?.filters,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async refresh() {
    await this.findAll(this.params)
  }

  async findAllForGallery(params) {
    const response = await get(
      `${params.galleryType}/${params.galleryId}/images`,
      {
        page: params.page,
      }
    )

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new AdminImagesCollection()
