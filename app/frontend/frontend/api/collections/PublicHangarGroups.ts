import { get } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class PublicHangarGroupsCollection extends BaseCollection<
  THangarGroup,
  undefined
> {
  primaryKey = "id";

  async findAll(username: string): Promise<TCollectionResponse<THangarGroup>> {
    const response = await get<THangarGroup[]>(`hangar-groups/${username}`);

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new PublicHangarGroupsCollection();
