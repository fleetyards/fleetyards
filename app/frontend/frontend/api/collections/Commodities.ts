import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class CommoditiesCollection extends BaseCollection<
  TCommodity,
  TCommodityParams
> {
  primaryKey = "id";

  async findAll(
    params: TCommodityParams
  ): Promise<TCollectionResponse<TCommodity>> {
    this.params = params;

    const response = await get<TCommodity[]>("commodities", {
      q: params.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }
}

export default new CommoditiesCollection();
