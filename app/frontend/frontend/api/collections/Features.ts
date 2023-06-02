import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class FeaturesCollection extends BaseCollection {
  records: string[] = [];

  async findAll(): Promise<string[]> {
    const response = await get("features");

    if (!response.error) {
      this.records = response.data;
    }

    return this.records;
  }
}

export default new FeaturesCollection();
