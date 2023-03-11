import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class ModelPaintsCollection extends BaseCollection<
  TModelPaint,
  TModelPaintParams
> {
  primaryKey = "id";

  async findAll(
    params: TModelPaintParams
  ): Promise<TCollectionResponse<TModelPaint>> {
    this.params = params;

    const response = await get<TModelPaint[]>("model-paints", {
      q: params.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findAllByModel(
    modelSlug: string
  ): Promise<TCollectionResponse<TModelPaint>> {
    const response = await get<TModelPaint[]>(`models/${modelSlug}/paints`);

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelPaintsCollection();
