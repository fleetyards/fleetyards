import { get } from 'frontend/api/client'
import BaseCollection from 'frontend/api/collections/Base'

export class AdminImagesCollection extends BaseCollection {
  primaryKey: string = 'id'

  records: AdminImage[] = []

  params: AdminImageParams | null = null

  async findAll(params: AdminImageParams | null): Promise<AdminImage[]> {
    this.params = params

    const response = await get('images', {
      q: params?.filters,
      page: params?.page,
    })

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params)
  }

  async findAllForGallery(params: AdminGalleryParams): Promise<AdminImage[]> {
    const response = await get(
      `${params.galleryType}/${params.galleryId}/images`,
      {
        page: params.page,
      },
    )

    if (!response.error) {
      this.records = response.data
      this.setPages(response.meta)
    }

    return this.records
  }
}

export default new AdminImagesCollection()
