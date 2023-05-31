import { get } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class ImagesCollection extends BaseCollection<
  TImage,
  TCollectionParams<undefined>
> {
  primaryKey = "id";

  async findAll(params: TImageParams): Promise<TCollectionResponse<TImage>> {
    let path = "images";
    if (params.filters?.galleryType) {
      path = `${params.filters.galleryType}/${params.filters.gallerySlug}/images`;
    }
    const response = await get<TImage[]>(path, {
      page: params.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async random(): Promise<TCollectionResponse<TImage>> {
    const response = await get<TImage[]>("images/random");

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ImagesCollection();
