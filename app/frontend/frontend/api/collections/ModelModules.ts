import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class ModelModulesCollection extends BaseCollection<
  TModelModule,
  undefined
> {
  async findAll(slug: string): Promise<TCollectionResponse<TModelModule>> {
    if (prefetch("model-modules")) {
      this.records = prefetch("model-modules");
      return {
        data: this.records,
      };
    }

    const response = await get<TModelModule[]>(`models/${slug}/modules`);

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelModulesCollection();
