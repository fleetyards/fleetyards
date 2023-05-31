import { get, post } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class CommodityPricesCollection extends BaseCollection<
  TCommodityPrice,
  undefined
> {
  primaryKey = "id";

  async create(
    form: TCommodityPriceForm
  ): Promise<TRecordResponse<TCommodityPrice>> {
    const response = await post<TCommodityPrice>("commodity-prices", form);

    return this.recordResponse(response.data, response.error);
  }

  async timeRanges(): Promise<TFilterGroupItem[]> {
    const response = await get<TFilterGroupItem[]>(
      "commodity-prices/time-ranges"
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }
}

export default new CommodityPricesCollection();
