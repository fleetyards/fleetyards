import { prefetch } from "@/frontend/api/prefetch";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type {
  CelestialObjectMinimal,
  CelestialObjectQuery,
} from "@/services/fyApi";
import BaseCollection from "./Base";

interface CelestialObjectParams extends CollectionParams {
  filters: CelestialObjectQuery;
}

const { celestialObjects } = useApiClient();

export class CelestialObjectCollection extends BaseCollection {
  records: CelestialObjectMinimal[] = [];

  record?: CelestialObjectMinimal;

  params?: CelestialObjectParams;

  async list(params: CelestialObjectParams): Promise<CelestialObjectMinimal[]> {
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
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async get(slug: string): Promise<CelestialObjectMinimal | undefined> {
    if (prefetch("celestialObject")) {
      this.record = prefetch("celestialObject");
      return this.record;
    }

    try {
      this.record = await celestialObjects.get({ slug });
    } catch (error) {
      console.error(error);
    }

    return this.record;
  }
}

export default new CelestialObjectCollection();
