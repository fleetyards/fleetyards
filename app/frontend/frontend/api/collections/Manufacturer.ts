import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class ManufacturerCollection extends BaseCollection<
  TManufacturer,
  TManufacturerParams
> {
  primaryKey = "id";

  async findAll(
    params: TManufacturerParams
  ): Promise<TCollectionResponse<TManufacturer>> {
    this.params = params;

    const response = await get<TManufacturer[]>("manufacturers", {
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

export default new ManufacturerCollection();
