import { put, destroy, download } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { VehicleMinimal } from "@/services/fyApi/models/VehicleMinimal";
import type { HangarQuery, HangarStats } from "@/services/fyApi";
import BaseCollection from "./Base";

export interface HangarParams extends CollectionParams {
  filters: HangarQuery;
}

const { hangar } = useApiClient();

export class HangarCollection extends BaseCollection {
  primaryKey = "id";

  records: VehicleMinimal[] = [];

  stats?: HangarStats;

  params: HangarParams | null = null;

  lastUsedMethod = "findAll";

  get perPage(): string {
    return Store.getters["hangar/perPage"];
  }

  get perPageSteps(): string[] {
    return ["15", "30", "60", "120", "240", "all"];
  }

  updatePerPage(perPage: string) {
    Store.dispatch("hangar/updatePerPage", perPage);
  }

  async findAll(params: HangarParams | null): Promise<VehicleMinimal[]> {
    this.lastUsedMethod = "findAll";
    this.params = params;

    try {
      const response = await hangar.get({
        q: params?.filters,
        page: params?.page,
        perPage: this.perPage,
      });

      this.records = response.items;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params);
  }

  async export(params: HangarParams): Promise<Vehicle[] | null> {
    const response = await download("hangar/export", {
      q: params.filters,
    });

    if (!response.error) {
      return response.data;
    }

    return null;
  }

  async destroyAll(): Promise<boolean> {
    const response = await destroy("hangar");

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async ingameMoveToWishlist(): Promise<boolean> {
    const response = await put("hangar/move-all-ingame-to-wishlist");

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async destroyAllIngame(): Promise<boolean> {
    const response = await destroy("vehicles/destroy-all-ingame");

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async syncRsiHangar(
    items: TRSIHangarItem[]
  ): Promise<THangarSyncResult | null> {
    const response = await put("hangar/sync-rsi-hangar", {
      items,
    });

    if (!response.error) {
      this.refresh();

      return response.data;
    }

    return null;
  }
}

export default new HangarCollection();
