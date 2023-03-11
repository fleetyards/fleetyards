import { post } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class FleetMembershipsCollection extends BaseCollection<
  TFleetMember,
  undefined
> {
  async useInvite(
    form: TFleetMemberInviteForm
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await post<TFleetMember>(`fleets/use-invite`, form);

    return this.recordResponse(response.data, response.error);
  }
}

export default new FleetMembershipsCollection();
