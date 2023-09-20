import BaseCollection from "@/frontend/api/collections/Base";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { Image } from "@/services/fyAdminApi/models/Image";
import type { ImageQuery } from "@/services/fyAdminApi/models/ImageQuery";

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
      const response = await images.images({
        q: params?.filters,
        page: params?.page ? String(params?.page) : undefined,
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
    try {
      const response = await images.images({
        q: {
          galleryTypeEq: params.galleryType,
          galleryIdEq: params.galleryId,
        },
        page: params?.page ? String(params?.page) : undefined,
      });

      this.records = response.items;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }
}

export default new AdminImagesCollection();
