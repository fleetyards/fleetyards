import { get } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class FleetInvitesCollection extends BaseCollection<
  TFleetInvite,
  undefined
> {
  primaryKey = "id";

  async findAllForCurrent(
    identifier = "default"
  ): Promise<TCollectionResponse<TFleetInvite>> {
    const response = await get<TFleetInvite[]>(`fleets/invites`, {
      [identifier]: true,
    });

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }
}

export default new FleetInvitesCollection();
