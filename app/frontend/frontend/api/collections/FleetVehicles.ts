import { get, download } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class FleetVehiclesCollection extends BaseCollection {
  primaryKey = "id";

  records: (Vehicle | Model)[] = [];

  stats: FleetVehicleStats | null = null;

  modelCounts: FleetModelCounts | null = null;

  get perPage(): number {
    return Store.getters["fleet/perPage"];
  }

  get perPageSteps(): (number | "all")[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage: number | "all") {
    Store.dispatch("fleet/updatePerPage", perPage);
  }

  async findAll(params: FleetVehicleParams): Promise<(Vehicle | Model)[]> {
    const response = await get(`fleets/${params.slug}/vehicles`, {
      q: params?.filters,
      page: params?.page,
      perPage: params?.perPage || this.perPage,
      grouped: params?.grouped,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.records;
  }

  async findStats(
    params: FleetVehicleParams
  ): Promise<FleetVehicleStats | null> {
    const response = await get(`fleets/${params.slug}/quick-stats`, {
      q: params?.filters,
    });

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }

  async findModelCounts(
    params: FleetVehicleParams
  ): Promise<FleetModelCounts | null> {
    const response = await get(`fleets/${params.slug}/model-counts`, {
      q: params?.filters,
    });

    if (!response.error) {
      this.modelCounts = response.data;
    }

    return this.modelCounts;
  }

  async export(params: FleetVehicleParams): Promise<Vehicle[] | null> {
    const response = await download(`fleets/${params.slug}/vehicles/export`, {
      q: params?.filters,
    });

    if (!response.error) {
      return response.data;
    }

    return null;
  }
}

export default new FleetVehiclesCollection();
