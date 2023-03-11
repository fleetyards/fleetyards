import { get } from "@/frontend/api/client";
import { prefetch } from "@/frontend/api/prefetch";
import BaseCollection from "./Base";

export class CelestialObjectCollection extends BaseCollection<
  TCelestialObject,
  TCelestialObjectParams
> {
  async findAll(
    params: TCelestialObjectParams
  ): Promise<TCollectionResponse<TCelestialObject>> {
    if (prefetch("celestialObjects")) {
      this.records = prefetch("celestialObjects");
      return {
        data: this.records,
      };
    }

    this.params = params;

    const response = await get<TCelestialObject[]>("celestial-objects", {
      q: params.filters,
      page: params.page,
      cacheId: params.cacheId,
    });

    if (response.data) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlug(slug: string): Promise<TRecordResponse<TCelestialObject>> {
    if (prefetch("celestialObject")) {
      this.record = prefetch("celestialObject");

      if (this.record) {
        return {
          data: this.record,
        };
      }
    }

    const response = await get<TCelestialObject>(`celestial-objects/${slug}`);

    return this.recordResponse(response.data, response.error, true);
  }
}

export default new CelestialObjectCollection();
