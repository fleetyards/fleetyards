import { get } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class PublicFleetVehiclesCollection extends BaseCollection<
  TVehicle | TModel,
  undefined
> {
  primaryKey = "id";

  stats: TFleetVehicleStats | null = null;

  modelCounts: TFleetModelCounts | null = null;

  get perPage(): number | string {
    return Store.getters["publicFleet/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage) {
    Store.dispatch("publicFleet/updatePerPage", perPage);
  }

  async findAll(
    params: TFleetVehicleParams
  ): Promise<TCollectionResponse<TVehicle | TModel>> {
    const response = await get<(TVehicle | TModel)[]>(
      `fleets/${params.slug}/public-vehicles`,
      {
        q: params?.filters,
        page: params?.page,
        grouped: params?.grouped,
        perPage: this.perPage,
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
      `fleets/${params.slug}/public-model-counts`,
      {
        q: params?.filters,
      }
    );

    if (!response.error) {
      this.modelCounts = response.data;
    }

    return this.modelCounts;
  }
}

export default new PublicFleetVehiclesCollection();
