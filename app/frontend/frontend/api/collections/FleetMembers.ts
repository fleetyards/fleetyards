import { get, post, put } from "@/frontend/api/client";

import BaseCollection from "./Base";

export class FleetMembersCollection extends BaseCollection<
  TFleetMember,
  TFleetMembersParams
> {
  primaryKey = "id";

  stats: TFleetMemberStats | null = null;

  async findAll(
    params?: TFleetMembersParams
  ): Promise<TCollectionResponse<TFleetMember>> {
    const response = await get<TFleetMember[]>(
      `fleets/${params?.slug}/members`,
      {
        q: params?.filters,
        page: params?.page,
      }
    );

    this.params = params;

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findStats(
    params: TFleetMembersParams | null
  ): Promise<TFleetMemberStats | null> {
    const response = await get<TFleetMemberStats>(
      `fleets/${params?.slug}/member-quick-stats`,
      {
        q: params?.filters,
      }
    );

    if (!response.error) {
      this.stats = response.data;
    }

    return this.stats;
  }

  async findByFleet(slug: string): Promise<TRecordResponse<TFleetMember>> {
    const response = await get<TFleetMember>(`fleets/${slug}/members/current`);

    return this.recordResponse(response.data, response.error, true);
  }

  async create(
    slug: string,
    form: TFleetMemberForm,
    refetch = false
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await post<TFleetMember>(`fleets/${slug}/members`, form);

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }

  async update(
    slug: string,
    form: TFleetMembershipForm,
    refetch = false
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await put<TFleetMember>(`fleets/${slug}/members`, form);

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }

  async leave(
    slug: string,
    refetch = false
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await put<TFleetMember>(`fleets/${slug}/members/leave`);

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }

  async acceptRequest(
    slug: string,
    username: string,
    refetch = false
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await put<TFleetMember>(
      `fleets/${slug}/members/${username}/accept-request`
    );

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }

  async declineRequest(
    slug: string,
    username: string,
    refetch = false
  ): Promise<TRecordResponse<TFleetMember>> {
    const response = await put<TFleetMember>(
      `fleets/${slug}/members/${username}/decline-request`
    );

    if (!response.error && refetch) {
      this.findAll(this.params);
    }

    return this.recordResponse(response.data, response.error);
  }
}

export default new FleetMembersCollection();
