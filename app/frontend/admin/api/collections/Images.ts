import { get, put, destroy } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class AdminImagesCollection extends BaseCollection<
  TAdminImage,
  TAdminImageParams
> {
  primaryKey = "id";

  async findAll(
    params?: TAdminImageParams
  ): Promise<TCollectionResponse<TAdminImage>> {
    this.params = params;

    const response = await get<TAdminImage[]>("images", {
      q: params?.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params);
  }

  async findAllForGallery(
    params: TAdminGalleryParams
  ): Promise<TCollectionResponse<TAdminImage>> {
    const response = await get<TAdminImage[]>(
      `${params.galleryType}/${params.galleryId}/images`,
      {
        page: params.page,
      }
    );

    if (!response.error) {
      this.records = (response as TCollectionSuccessResponse<TAdminImage>).data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async update(
    id: string,
    params: Partial<TAdminImage>
  ): Promise<TRecordResponse<TAdminImage>> {
    const response = await put<TAdminImage>(`images/${id}`, params);

    return this.recordResponse(response.data, response.error);
  }

  async destroy(id: string): Promise<TRecordResponse<TAdminImage>> {
    const response = await destroy<TAdminImage>(`images/${id}`);

    return this.recordResponse(response.data, response.error);
  }
}

export default new AdminImagesCollection();
