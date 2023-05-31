import { get } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";

import BaseCollection from "./Base";

export class PublicVehiclesCollection extends BaseCollection<
  TVehicle,
  TPublicVehicleParams
> {
  primaryKey = "id";

  stats: TPublicVehicleStats | null = null;

  username: string | null = null;

  get perPage(): number | string {
    return Store.getters["publicHangar/perPage"];
  }

  get perPageSteps(): (number | "all")[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage: number | "all") {
    Store.dispatch("publicHangar/updatePerPage", perPage);
  }

  async findAll(
    params?: TPublicVehicleParams
  ): Promise<TCollectionResponse<TVehicle>> {
    if (!params?.username) {
      return {
        data: [],
      };
    }

    this.params = params;

    const response = await get<TVehicle[]>(
      `public/hangars/${params?.username}`,
      {
        q: params?.filters,
        page: params?.page,
        perPage: this.perPage,
      }
    );

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params);
  }

  async findStats(
    params: TPublicVehicleParams
  ): Promise<TPublicVehicleStats | null> {
    const response = await get<TPublicVehicleStats>(
      `public/hangars/${params.username}/stats`,
      {
        q: params.filters,
      }
    );

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }
}

export default new PublicVehiclesCollection();
