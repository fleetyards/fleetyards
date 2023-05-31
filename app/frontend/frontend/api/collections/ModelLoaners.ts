import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class ModelLoanersCollection extends BaseCollection {
  records: ModelLoaner[] = [];

  async findAll(slug: string): Promise<ModelLoaner[]> {
    if (prefetch("model-loaners")) {
      this.records = prefetch("model-loaners");
      return this.records;
    }

    const response = await get(`models/${slug}/loaners`);

    if (!response.error) {
      this.records = response.data;
      this.loaded = true;
    }

    return this.records;
  }
}

export default new ModelLoanersCollection();
