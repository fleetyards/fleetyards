import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";
import BaseCollection from "./Base";

export class StarsystemCollection extends BaseCollection<
  TStarsystem,
  TStarsystemParams
> {
  async findAll(
    params: TStarsystemParams
  ): Promise<TCollectionResponse<TStarsystem>> {
    if (prefetch("starsystems")) {
      this.records = prefetch("starsystems");

      return {
        data: this.records,
      };
    }

    this.params = params;

    const response = await get<TStarsystem[]>("starsystems", {
      q: params.filters,
      page: params.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlug(slug: string): Promise<TRecordResponse<TStarsystem>> {
    if (prefetch("starsystem")) {
      this.record = prefetch("starsystem");

      if (this.record) {
        return {
          data: this.record,
        };
      }
    }

    const response = await get<TStarsystem>(`starsystems/${slug}`);

    return this.recordResponse(response.data, response.error, true);
  }
}

export default new StarsystemCollection();
