import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { Image, ImageQuery } from "@/services/fyAdminApi";

interface AdminGalleryParams extends CollectionParams {
  galleryType: string;
  galleryId: string;
}

interface AdminImageParams extends CollectionParams {
  filters: ImageQuery;
}

const { images } = useApiClient();

export class AdminImagesCollection extends BaseCollection {
  primaryKey = "id";

  records: Image[] = [];

  params: AdminImageParams | null = null;

  async findAll(params: AdminImageParams | null): Promise<Image[]> {
    this.params = params;

    try {
      const response = await images.list({
        q: params?.filters,
        page: params?.page,
      });

      this.records = response.items;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params);
  }

  async findAllForGallery(params: AdminGalleryParams): Promise<Image[]> {
    const response = await get(
      `${params.galleryType}/${params.galleryId}/images`,
      {
        page: params.page,
      }
    );

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta || undefined);
    }

    return this.records;
  }
}

export default new AdminImagesCollection();
