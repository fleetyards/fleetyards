import { get } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class TradeRoutesCollection extends BaseCollection<
  TTradeRoute,
  TTradeRouteParams
> {
  primaryKey = "id";

  async findAll(
    params?: TTradeRouteParams
  ): Promise<TCollectionResponse<TTradeRoute>> {
    this.params = params;

    const response = await get<TTradeRoute[]>("trade-routes", {
      q: params?.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }
}
export default new TradeRoutesCollection();
