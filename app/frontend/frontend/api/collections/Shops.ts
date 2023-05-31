import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class ShopsCollection extends BaseCollection<TShop, TShopParams> {
  primaryKey = "id";

  async findAll(params: TShopParams): Promise<TCollectionResponse<TShop>> {
    this.params = params;

    const response = await get<TShop[]>("shops", {
      q: params.filters,
      page: params.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlugAndStation(
    params: TShopParams
  ): Promise<TRecordResponse<TShop>> {
    if (prefetch("shop")) {
      this.record = prefetch("shop");

      if (this.record) {
        return {
          data: this.record,
        };
      }
    }

    const response = await get<TShop>(
      `stations/${params?.stationSlug}/shops/${params?.slug}`
    );

    return this.recordResponse(response.data, response.error, true);
  }
}

export default new ShopsCollection();
