import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class ModelHardpointsCollection extends BaseCollection<
  TModelHardpoint,
  undefined
> {
  primaryKey = "id";

  async findAllByModel(
    modelSlug: string
  ): Promise<TCollectionResponse<TModelHardpoint>> {
    const response = await get<TModelHardpoint[]>(
      `models/${modelSlug}/hardpoints`
    );

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelHardpointsCollection();
