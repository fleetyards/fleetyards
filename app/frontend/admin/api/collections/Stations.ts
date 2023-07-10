import BaseCollection from "@/frontend/api/collections/Base";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { Station } from "@/services/fyAdminApi/models/Station";
import type { StationQuery } from "@/services/fyAdminApi/models/StationQuery";

const { stations } = useApiClient();

interface AdminStationParams extends CollectionParams {
  filters: StationQuery;
}

export class AdminStationsCollection extends BaseCollection {
  primaryKey = "id";

  records: Station[] = [];

  params: AdminStationParams | null = null;

  async findAll(params: AdminStationParams): Promise<Station[]> {
    this.params = params;

    try {
      const response = await stations.stations({
        q: params.filters,
        page: String(params.page),
      });

      this.records = response.items;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }
}

export default new AdminStationsCollection();
