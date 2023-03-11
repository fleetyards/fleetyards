import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class ComponentsCollection extends BaseCollection<
  TComponent,
  TComponentParams
> {
  primaryKey = "id";

  async findAll(
    params: TComponentParams
  ): Promise<TCollectionResponse<TComponent>> {
    this.params = params;

    const response = await get<TComponent[]>("components", {
      q: params.filters,
      page: params?.page,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }
}

export default new ComponentsCollection();
