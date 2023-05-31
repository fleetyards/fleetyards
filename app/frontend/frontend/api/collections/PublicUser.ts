import { get } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class PublicUserCollection extends BaseCollection<TUser, undefined> {
  async findByUsername(username: string): Promise<TRecordResponse<TUser>> {
    const response = await get<TUser>(`users/${username}`);

    if (!response.error) {
      this.record = response.data;
    }

    return this.recordResponse(response.data, response.error, true);
  }
}

export default new PublicUserCollection();
