import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";
import Store from "@/frontend/lib/Store";
import BaseCollection from "./Base";

export class ModelsCollection extends BaseCollection<TModel, TModelParams> {
  get perPage(): number {
    return Store.getters["models/perPage"];
  }

  get perPageSteps(): (number | string)[] {
    return [15, 30, 60, 120, 240];
  }

  updatePerPage(perPage) {
    Store.dispatch("models/updatePerPage", perPage);
  }

  async findAll(params: TModelParams): Promise<TCollectionResponse<TModel>> {
    if (prefetch("models")) {
      this.records = prefetch("models");
      return {
        data: this.records,
      };
    }

    this.params = params;

    const response = await get<TModel[]>("models", {
      q: params.filters,
      page: params.page,
      perPage: this.perPage,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlug(slug: string): Promise<TRecordResponse<TModel>> {
    if (prefetch("model")) {
      this.record = prefetch("model");

      if (this.record) {
        return {
          data: this.record,
        };
      }
    }

    const response = await get<TModel>(`models/${slug}`);

    return this.recordResponse(response.data, response.error, true);
  }

  async latest(): Promise<TCollectionResponse<TModel>> {
    const response = await get<TModel[]>("models/latest");

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }

  async modules(slug: string): Promise<TModelModule[]> {
    const response = await get<TModelModule[]>(`models/${slug}/modules`);

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async upgrades(slug: string): Promise<TModelUpgrade[]> {
    const response = await get<TModelUpgrade[]>(`models/${slug}/upgrades`);

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async variants(slug: string): Promise<TModel[]> {
    const response = await get<TModel[]>(`models/${slug}/variants`);

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async loaners(slug: string): Promise<TModelLoaner[]> {
    const response = await get<TModelLoaner[]>(`models/${slug}/loaners`);

    if (!response.error) {
      return response.data;
    }

    return [];
  }
}

export default new ModelsCollection();
