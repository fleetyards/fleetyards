import { get, post, put, destroy } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class HangarGroupsCollection extends BaseCollection<
  THangarGroup,
  undefined
> {
  primaryKey = "id";

  async findAll(): Promise<TCollectionResponse<THangarGroup>> {
    const response = await get<THangarGroup[]>("hangar/groups");

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }

  async create(
    form: THangarGroupForm,
    refetch = false
  ): Promise<TRecordResponse<THangarGroup>> {
    const response = await post<THangarGroup>("hangar/groups", form);

    if (!response.error && refetch) {
      this.findAll();
    }

    return this.recordResponse(response.data, response.error);
  }

  async update(
    hangarGroupId: string,
    form: THangarGroupForm
  ): Promise<TRecordResponse<THangarGroup>> {
    const response = await put<THangarGroup>(
      `hangar/groups/${hangarGroupId}`,
      form
    );

    if (!response.error) {
      this.findAll();
    }

    return this.recordResponse(response.data, response.error);
  }

  async destroy(hangarGroupId: string): Promise<TRecordResponse<THangarGroup>> {
    const response = await destroy<THangarGroup>(
      `hangar/groups/${hangarGroupId}`
    );

    if (!response.error) {
      this.findAll();
    }

    return this.recordResponse(response.data, response.error);
  }
}

export default new HangarGroupsCollection();
