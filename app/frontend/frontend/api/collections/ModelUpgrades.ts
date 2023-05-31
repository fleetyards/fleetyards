import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class ModelUpgradesCollection extends BaseCollection<
  TModelUpgrade,
  undefined
> {
  async findAll(slug: string): Promise<TCollectionResponse<TModelUpgrade>> {
    if (prefetch("model-modules")) {
      this.records = prefetch("model-modules");

      return {
        data: this.records,
      };
    }

    const response = await get<TModelUpgrade[]>(`models/${slug}/upgrades`);

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelUpgradesCollection();
