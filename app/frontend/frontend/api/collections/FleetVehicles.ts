import { get, download } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class FleetVehiclesCollection extends BaseCollection<
  TVehicle | TModel,
  TFleetVehicleParams
> {
  primaryKey = "id";

  stats: TFleetVehicleStats | null = null;

  modelCounts: TFleetModelCounts | null = null;

  get perPage(): number {
    return Store.getters["fleet/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage) {
    Store.dispatch("fleet/updatePerPage", perPage);
  }

  async findAll(
    params: TFleetVehicleParams
  ): Promise<TCollectionResponse<TVehicle | TModel>> {
    const response = await get<(TVehicle | TModel)[]>(
      `fleets/${params.slug}/vehicles`,
      {
        q: params?.filters,
        page: params?.page,
        perPage: params?.perPage || this.perPage,
        grouped: params?.grouped,
      }
    );

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findStats(
    params: TFleetVehicleParams
  ): Promise<TFleetVehicleStats | null> {
    const response = await get<TFleetVehicleStats>(
      `fleets/${params.slug}/quick-stats`,
      {
        q: params?.filters,
      }
    );

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }

  async findModelCounts(
    params: TFleetVehicleParams
  ): Promise<TFleetModelCounts | null> {
    const response = await get<TFleetModelCounts>(
      `fleets/${params.slug}/model-counts`,
      {
        q: params?.filters,
      }
    );

    if (!response.error) {
      this.modelCounts = response.data;
    }

    return this.modelCounts;
  }

  async export(params: TFleetVehicleParams): Promise<TVehicle[] | null> {
    const response = await download<TVehicle[]>(
      `fleets/${params.slug}/vehicles/export`,
      {
        q: params?.filters,
      }
    );

    if (!response.error) {
      return response.data;
    }

    return null;
  }
}

export default new FleetVehiclesCollection();
