import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class ModelModulePackagesCollection extends BaseCollection<
  TModelModulePackage,
  undefined
> {
  async findAll(
    slug: string
  ): Promise<TCollectionResponse<TModelModulePackage>> {
    if (prefetch("model-module-packages")) {
      this.records = prefetch("model-modules-packages");

      return {
        data: this.records,
      };
    }

    const response = await get<TModelModulePackage[]>(
      `models/${slug}/module-packages`
    );

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new ModelModulePackagesCollection();
