import {
  get,
  post,
  put,
  destroy,
  download,
  ApiResponse,
  ApiErrorResponse,
} from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class VehiclesCollection extends BaseCollection {
  primaryKey = "id";

  records: Vehicle[] = [];

  stats: VehicleStats | null = null;

  params: VehicleParams | null = null;

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

  async findAll(params: VehicleParams | null): Promise<Vehicle[]> {
    this.lastUsedMethod = "findAll";
    this.params = params;

    const response = await get("hangar", {
      q: params?.filters,
      page: params?.page,
      perPage: this.perPage,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.records;
  }

  async refresh(): Promise<void> {
    await this[this.lastUsedMethod || "findAll"](this.params);
  }

  async findStats(params: VehicleParams): Promise<VehicleStats | null> {
    const response = await get("hangar/stats", {
      q: params.filters,
    });

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }

  async export(params: VehicleParams): Promise<Vehicle[] | null> {
    const response = await download("hangar/export", {
      q: params.filters,
    });

    if (!response.error) {
      return response.data;
    }

    return null;
  }

  async create(form: VehicleForm, refresh = false): Promise<Vehicle | null> {
    const response = await post("vehicles", form);

    if (!response.error) {
      if (refresh) {
        this.refresh();
      }

      return response.data;
    }

    return null;
  }

  async update(
    id: string,
    form: VehicleForm
  ): Promise<ApiResponse | ApiErrorResponse> {
    const response = await put(`vehicles/${id}`, form);

    if (!response.error) {
      this.refresh();
    }

    return response;
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
}

export default new VehiclesCollection();
