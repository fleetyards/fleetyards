import { get } from "@/frontend/api/client";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class PublicWishlistCollection extends BaseCollection<
  TVehicle,
  TPublicVehicleParams
> {
  primaryKey = "id";

  username: string | null = null;

  get perPage(): number | string {
    return Store.getters["publicWishlist/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240, "all"];
  }

  updatePerPage(perPage) {
    Store.dispatch("publicWishlist/updatePerPage", perPage);
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
      `vehicles/${params?.username}/wishlist`,
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
}

export default new PublicWishlistCollection();
