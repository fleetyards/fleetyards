import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class AdminImagesCollection extends BaseCollection<
  TAdminImage,
  TAdminImageParams
> {
  primaryKey = "id";

  async findAll(
    params?: TAdminImageParams
  ): Promise<TCollectionResponse<TAdminImage[]>> {
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

  async findAllForGallery(params: TAdminGalleryParams): Promise<TAdminImage[]> {
    const response = await get(
      `${params.galleryType}/${params.galleryId}/images`,
      {
        page: params.page,
      }
    );

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.records;
  }
}

export default new AdminImagesCollection();
