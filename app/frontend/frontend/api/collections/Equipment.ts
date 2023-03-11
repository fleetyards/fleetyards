import { get } from "@/frontend/api/client";
import BaseCollection from "@/frontend/api/collections/Base";

export class EquipmentCollection extends BaseCollection<
  TEquipment,
  TEquipmentParams
> {
  primaryKey = "id";

  async findAll(
    params: TEquipmentParams
  ): Promise<TCollectionResponse<TEquipment>> {
    this.params = params;

    const response = await get<TEquipment[]>("equipment", {
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

export default new EquipmentCollection();
