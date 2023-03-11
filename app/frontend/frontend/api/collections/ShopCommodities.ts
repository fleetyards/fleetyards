import { get } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class ShopCommoditiesCollection extends BaseCollection<
  TShopCommodity,
  TShopCommodityParams
> {
  primaryKey = "id";

  async findAll(
    params: TShopCommodityParams
  ): Promise<TCollectionResponse<TShopCommodity>> {
    this.params = params;

    const response = await get<TShopCommodity[]>(
      `stations/${params?.stationSlug}/shops/${params?.slug}/commodities`,
      {
        q: params.filters,
        page: params.page,
      }
    );

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async subCategories(
    stationSlug: string,
    shopSlug: string
  ): Promise<TShopCommoditySubCategroy[]> {
    const response = await get<TShopCommoditySubCategroy[]>(
      "filters/shop-commodities/sub-categories",
      {
        stationSlug,
        shopSlug,
      }
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }
}

export default new ShopCommoditiesCollection();
