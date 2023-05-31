import { get } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class SearchCollection extends BaseCollection<
  TSearchResult,
  TSearchParams
> {
  async findAll(
    params: TSearchParams
  ): Promise<TCollectionResponse<TSearchResult>> {
    this.params = params;

    const response = await get<TSearchResult[]>("search", {
      q: params.filters,
      page: params.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }
}

export default new SearchCollection();
