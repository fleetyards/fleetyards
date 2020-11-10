import { get } from 'frontend/api/client'
import BaseCollection from './Base'

export class ImagesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: Image[] = []

  async findAll(params: CollectionParams): Promise<Image[]> {
    const response = await get('images', {
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async findAllForGallery(params: GalleryParams): Promise<Image[]> {
    const response = await get(`${params.galleryType}/${params.slug}/images`, {
      page: params.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async random(): Promise<Image[]> {
    const response = await get('images/random')

    if (!response.error) {
      this.records = response.data
    }

    return this.records
  }
}

export default new ImagesCollection()
