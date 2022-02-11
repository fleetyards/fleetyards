import { get } from '@/frontend/api/client'
import BaseCollection from './Base'

export class ImagesCollection extends BaseCollection {
  primaryKey = 'id'

  records = []

  async findAll(params) {
    const response = await get('images', {
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllForGallery(params) {
    const response = await get(`${params.galleryType}/${params.slug}/images`, {
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async random() {
    const response = await get('images/random')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ImagesCollection()
