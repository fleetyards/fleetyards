import { get, put, destroy, download } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class WishlistCollection extends BaseCollection {
  primaryKey = "id";

  records: Vehicle[] = [];

  params: VehicleParams | null = null;

  lastUsedMethod = "findAll";

  get perPage(): number | string {
    return Store.getters["wishlist/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage) {
    Store.dispatch("wishlist/updatePerPage", perPage);
  }

  async findAll(params: VehicleParams | null): Promise<Vehicle[]> {
    this.lastUsedMethod = "findAll";
    this.params = params;

    const response = await get("wishlist", {
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

  async export(params: VehicleParams): Promise<Vehicle[] | null> {
    const response = await download("wishlist/export", {
      q: params.filters,
    });

    if (!response.error) {
      return response.data;
    }

    return null;
  }

  async addToHangar(id: string): Promise<boolean> {
    const response = await put(`vehicles/${id}`, {
      wanted: false,
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
    const response = await destroy("wishlist");

    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }
}

export default new WishlistCollection();
