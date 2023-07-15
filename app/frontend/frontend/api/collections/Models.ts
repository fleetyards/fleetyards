import { prefetch } from "@/frontend/api/prefetch";
import Store from "@/frontend/lib/Store";
import { useApiClient } from "@/frontend/composables/useApiClient";
import type { ModelMinimal } from "@/services/fyApi/models/ModelMinimal";
import type { ModelComplete } from "@/services/fyApi/models/ModelComplete";
import type { ModelQuery } from "@/services/fyApi/models/ModelQuery";
import BaseCollection from "./Base";

interface ModelParams extends CollectionParams {
  filters: ModelQuery;
}

const { models } = useApiClient();

export class ModelsCollection extends BaseCollection {
  records: ModelMinimal[] = [];

  record: ModelComplete | null = null;

  params: ModelParams | null = null;

  get perPage(): string {
    return Store.getters["models/perPage"];
  }

  get perPageSteps(): string[] {
    return ["15", "30", "60", "120", "240"];
  }

  updatePerPage(perPage: number | string) {
    Store.dispatch("models/updatePerPage", perPage);
  }

  async findAll(params: ModelParams): Promise<ModelMinimal[]> {
    if (prefetch("models")) {
      this.records = prefetch("models");
      return this.records;
    }

    this.params = params;

    try {
      const response = await models.list({
        q: params.filters,
        page: params.page,
        perPage: this.perPage,
      });

      this.records = response.items;
      this.loaded = true;
      this.setPages(response.meta?.pagination);
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async findBySlug(slug: string): Promise<ModelComplete | null> {
    if (prefetch("model")) {
      this.record = prefetch("model");
      return this.record;
    }

    try {
      this.record = await models.get({ slug });
    } catch (error) {
      console.error(error);
    }

    return this.record;
  }

  async latest(): Promise<ModelMinimal[]> {
    try {
      this.records = await models.latest();
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }

  async unscheduled(): Promise<ModelMinimal[]> {
    try {
      this.records = await models.unschduled();
    } catch (error) {
      console.error(error);
    }

    return this.records;
  }
}

export default new ModelsCollection();
