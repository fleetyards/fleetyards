import { prefetch } from "@/frontend/api/prefetch";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { CelestialObjectMinimal } from "@/services/fyApi/models/CelestialObjectMinimal";
import type { CelestialObjectQuery } from "@/services/fyApi/models/CelestialObjectQuery";
import BaseCollection from "./Base";

interface CelestialObjectParams extends CollectionParams {
  filters: CelestialObjectQuery;
}

const { celestialObjects } = useApiClient();

export class CelestialObjectCollection extends BaseCollection {
  records: CelestialObjectMinimal[] = [];

  record: CelestialObjectMinimal | null = null;

  params: CelestialObjectParams | null = null;

  async findAll(
    params: CelestialObjectParams
  ): Promise<CelestialObjectMinimal[]> {
    if (prefetch("celestialObjects")) {
      this.records = prefetch("celestialObjects");
      return this.records;
    }

    this.params = params;

    try {
      const response = await celestialObjects.list({
        q: params.filters,
        page: params.page,
        cacheId: params.cacheId,
      });

      this.records = response.items;
      this.loaded = true;
      this.setPages(response.meta.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }
}

export default new CelestialObjectCollection();
