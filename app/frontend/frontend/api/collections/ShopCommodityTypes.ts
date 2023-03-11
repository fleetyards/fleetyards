import { get } from "@/frontend/api/client";

export class ShopCommodityTypesCollection {
  records: TFilterGroupItem[] = [];

  async findAll(): Promise<TFilterGroupItem[]> {
    const response = await get<TFilterGroupItem[]>(
      `shop-commodities/commodity-type-options`
    );

    if (!response.error) {
      this.records = response.data;
    }

    return this.records;
  }
}

export default new ShopCommodityTypesCollection();
