import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";
import BaseCollection from "./Base";

export class ModelVariantsCollection extends BaseCollection {
  records: Model[] = [];

  async findAll(slug: string): Promise<Model[]> {
    if (prefetch("model-variants")) {
      this.records = prefetch("model-variants");
      return this.records;
    }

    const response = await get(`models/${slug}/variants`);

    if (!response.error) {
      this.records = response.data;
      this.loaded = true;
    }

    return this.records;
  }
}

export default new ModelVariantsCollection();
