import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class ModelPaintsCollection extends BaseCollection<
  TVideo,
  TVideoParams
> {
  primaryKey = "id";

  async findAll(params: TVideoParams): Promise<TCollectionResponse<TVideo>> {
    this.params = params;

    const response = await get<TVideo[]>(`models/${params.modelSlug}/videos`, {
      q: params.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelPaintsCollection();
