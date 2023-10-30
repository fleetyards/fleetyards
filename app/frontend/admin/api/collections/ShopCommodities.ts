import { post, put, destroy } from "@/admin/api/client";
import BaseCollection from "@/frontend/api/collections/Base";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { ShopCommodityQuery } from "@/services/fyAdminApi";

interface AdminShopCommodityParams extends CollectionParams {
  filters?: ShopCommodityQuery;
  shopId: string;
}

const { shops } = useApiClient();

export class AdminShopCommoditiesCollection extends BaseCollection {
  primaryKey = "id";

  records: AdminShopCommodity[] = [];

  params: AdminShopCommodityParams | null = null;

  async findAll(
    params: AdminShopCommodityParams,
  ): Promise<AdminShopCommodity[]> {
    this.params = params;

    try {
      const response = await shops.shopCommodities({
        shopId: params.shopId,
        filters: params.filters,
        page: params?.page ? String(params?.page) : undefined,
      });

      this.records = response.items;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async refresh(): Promise<void> {
    setTimeout(async () => {
      if (this.params) {
        await this.findAll(this.params);
      }
    }, 500);
  }

  async create(
    shopId: string,
    form: AdminShopCommodityForm,
    refetch = false,
  ): Promise<AdminShopCommodity | null> {
    const response = await post(`shops/${shopId}/commodities`, form);

    if (!response.error) {
      if (refetch) {
        this.refresh();
      }

      return response.data;
    }

    return null;
  }

  async update(
    shopId: string,
    id: string,
    form: AdminShopCommodityForm,
  ): Promise<boolean> {
    const response = await put(`shops/${shopId}/commodities/${id}`, form);
    if (!response.error) {
      this.refresh();

      return true;
    }

    return false;
  }

  async destroy(shopId: string, id: string): Promise<boolean> {
    const response = await destroy(`shops/${shopId}/commodities/${id}`);

    if (!response.error) {
      if (this.params) {
        this.findAll(this.params);
      }

      return true;
    }

    return false;
  }
}

export default new AdminShopCommoditiesCollection();
