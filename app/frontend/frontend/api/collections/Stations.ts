import { prefetch } from "@/frontend/api/prefetch";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type {
  StationMinimal,
  StationComplete,
  StationQuery,
} from "@/services/fyApi";
import BaseCollection from "./Base";

interface StationParams extends CollectionParams {
  filters: StationQuery;
}

const { stations } = useApiClient();

export class StationsCollection extends BaseCollection {
  records: StationMinimal[] = [];

  record?: StationComplete;

  params?: StationParams;

  async findAll(params: StationParams): Promise<StationMinimal[]> {
    this.params = params;

    try {
      const response = await stations.list({
        q: {
          ...params.filters,
          sorts: ["station_type asc", "name asc"],
        },
        page: params.page,
      });

      this.records = response.items;
      this.loaded = true;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async get(slug: string): Promise<StationComplete | undefined> {
    if (prefetch("station")) {
      this.record = prefetch("station");
      return this.record;
    }

    try {
      this.record = await stations.get({ slug });
    } catch (error) {
      console.error(error);
    }

    return this.record;
  }
}

export default new StationsCollection();
