import BaseCollection from "@/frontend/api/collections/Base";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { Station } from "@/services/fyAdminApi/models/Station";

const { stations } = useApiClient();

export class AdminStationsCollection extends BaseCollection {
  primaryKey = "id";

  records: Station[] = [];

  params: AdminAdminStationParams | null = null;

  async findAll(params: AdminAdminStationParams): Promise<Station[]> {
    this.params = params;

    try {
      const response = await stations.list({
        q: params.filters,
        page: params.page,
      });

      this.records = response.items;
      this.setPages(response.meta.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }
}

export default new AdminStationsCollection();
