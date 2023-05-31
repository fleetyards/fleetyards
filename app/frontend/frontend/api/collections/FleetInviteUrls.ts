import { get, post, destroy } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class FleetInviteUrlsCollection extends BaseCollection<
  TFleetInviteUrl,
  TFleetInviteUrlParams
> {
  primaryKey = "token";

  async findAll(
    params?: TFleetInviteUrlParams
  ): Promise<TCollectionResponse<TFleetInviteUrl>> {
    const response = await get<TFleetInviteUrl[]>(
      `fleets/${params?.fleetSlug}/invite-urls/`
    );

    this.params = params;

    if (!response.error) {
      this.records = response.data;
    }

    return this.collectionResponse(response.error);
  }

  async checkToken(fleetSlug: string, token: string): Promise<boolean> {
    const response = await get(
      `fleets/${fleetSlug}/invite-urls/${token}/exists`
    );

    if (!response.error) {
      return true;
    }

    return false;
  }

  async findByToken(
    fleetSlug: string,
    token: string
  ): Promise<TRecordResponse<TFleetInviteUrl>> {
    const response = await get<TFleetInviteUrl>(
      `fleets/${fleetSlug}/invite-urls/${token}`
    );

    return this.recordResponse(response.data, response.error);
  }

  async create(
    form: TInviteUrlForm,
    refetch = false
  ): Promise<TRecordResponse<TFleetInviteUrl>> {
    const response = await post<TFleetInviteUrl>(
      `fleets/${form.fleetSlug}/invite-urls`,
      form
    );

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }

  async destroy(
    fleetSlug: string,
    token: string,
    refetch = false
  ): Promise<TRecordResponse<TFleetInviteUrl>> {
    const response = await destroy<TFleetInviteUrl>(
      `fleets/${fleetSlug}/invite-urls/${token}`
    );

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }
}

export default new FleetInviteUrlsCollection();
