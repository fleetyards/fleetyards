import { get, post, put, destroy, download } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class VehiclesCollection extends BaseCollection<
  TVehicle,
  TVehicleParams
> {
  primaryKey = "id";

  stats: TVehicleStats | null = null;

  lastUsedMethod = "findAll";

  get perPage(): number | string {
    return Store.getters["hangar/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage) {
    Store.dispatch("hangar/updatePerPage", perPage);
  }

  async findAll(
    params?: TVehicleParams
  ): Promise<TCollectionResponse<TVehicle>> {
    this.params = params;

    const response = await get<TVehicle[]>("hangar", {
      q: params?.filters,
      page: params?.page,
      perPage: this.perPage,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async refresh(): Promise<void> {
    await this.findAll(this.params);
  }

  async findStats(params: TVehicleParams): Promise<TVehicleStats | null> {
    const response = await get<TVehicleStats>("hangar/stats", {
      q: params.filters,
    });

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }

  async export(params: TVehicleParams): Promise<TVehicle[] | null> {
    const response = await download<TVehicle[]>("hangar/export", {
      q: params.filters,
    });

    if (!response.error) {
      return response.data;
    }

    return null;
  }

  async create(
    form: TVehicleForm,
    refresh = false
  ): Promise<TRecordResponse<TVehicle>> {
    const response = await post<TVehicle>("vehicles", form);

    if (!response.error && refresh) {
      this.refresh();
    }

    return this.recordResponse(response.data, response.error);
  }

  async update(
    id: string,
    form: TVehicleForm
  ): Promise<TRecordResponse<TVehicle>> {
    const response = await put<TVehicle>(`vehicles/${id}`, form);

    if (!response.error) {
      this.refresh();
    }

    return this.recordResponse(response.data, response.error);
  }

  async addToWishlist(id: string): Promise<boolean> {
    const response = await put(`vehicles/${id}`, {
      wanted: true,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async addToWishlistBulk(ids: string): Promise<boolean> {
    const response = await put(`vehicles/bulk`, {
      wanted: true,
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async addToHangarBulk(ids: string): Promise<boolean> {
    const response = await put(`vehicles/bulk`, {
      wanted: false,
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async hideFromPublicHangar(ids: string): Promise<boolean> {
    const response = await put(`vehicles/bulk`, {
      public: false,
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async showOnPublicHangar(ids: string): Promise<boolean> {
    const response = await put(`vehicles/bulk`, {
      public: true,
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async updateHangarGroupsBulk(
    ids: string,
    hangarGroupIds: string[]
  ): Promise<boolean> {
    const response = await put(`vehicles/bulk`, {
      hangarGroupIds,
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async destroy(id: string): Promise<boolean> {
    const response = await destroy(`vehicles/${id}`);

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async destroyBulk(ids: string[]): Promise<boolean> {
    const response = await put("vehicles/destroy-bulk", {
      ids,
    });

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
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

export default new VehiclesCollection();
