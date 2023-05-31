import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";

import BaseCollection from "./Base";

export class StationsCollection extends BaseCollection<
  TStation,
  TStationParams
> {
  async findAll(
    params: TStationParams
  ): Promise<TCollectionResponse<TStation>> {
    this.params = params;

    const response = await get<TStation[]>("stations", {
      q: {
        ...params.filters,
        sorts: ["station_type asc", "name asc"],
      },
      page: params.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlug(slug: string): Promise<TRecordResponse<TStation>> {
    if (prefetch("station")) {
      this.record = prefetch("station");

      if (this.record) {
        return {
          data: this.record,
        };
      }
    }

    const response = await get<TStation>(`stations/${slug}`);

    if (!response.error) {
      this.record = response.data;
    }

    return this.recordResponse(response.data, response.error, true);
  }
}

export default new StationsCollection();
