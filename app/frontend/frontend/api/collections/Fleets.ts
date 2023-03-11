import { get, post } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class FleetsCollection extends BaseCollection<TFleet, undefined> {
  async findAllForCurrent(
    identifier = "default"
  ): Promise<TCollectionResponse<TFleet>> {
    const response = await get<TFleet[]>(`fleets/current`, {
      [identifier]: true,
    });

    if (!response.error) {
      this.records = response.data;
      this.setPages(response.meta);
    }

    return this.collectionResponse(response.error);
  }

  async findBySlug(slug: string): Promise<TRecordResponse<TFleet>> {
    const response = await get<TFleet>(`fleets/${slug}`);

    return this.recordResponse(response.data, response.error, true);
  }

  // tslint:disable-next-line variable-name
  async create(
    form: TFleetForm,
    _refetch = false
  ): Promise<TRecordResponse<TFleet>> {
    const response = await post<TFleet>("fleets", form);

    return this.recordResponse(response.data, response.error, true);
  }

  async findModelsByClassificationBySlug(slug: string): Promise<TChartData[]> {
    const response = await get<TChartData[]>(
      `fleets/${slug}/stats/models-by-classification`
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async findVehiclesByModelBySlug(
    slug: string,
    limit?: number
  ): Promise<TChartData[]> {
    const response = await get<TChartData[]>(
      `fleets/${slug}/stats/vehicles-by-model`,
      {
        limit,
      }
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async findModelsBySizeBySlug(slug: string): Promise<TChartData[]> {
    const response = await get<TChartData[]>(
      `fleets/${slug}/stats/models-by-size`
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async findModelsByManufacturerBySlug(slug: string): Promise<TChartData[]> {
    const response = await get<TChartData[]>(
      `fleets/${slug}/stats/models-by-manufacturer`
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async findModelsByProductionStatusBySlug(
    slug: string
  ): Promise<TChartData[]> {
    const response = await get<TChartData[]>(
      `fleets/${slug}/stats/models-by-production-status`
    );

    if (!response.error) {
      return response.data;
    }

    return [];
  }

  async checkInvite(token: string): Promise<TRecordResponse<TFleet>> {
    const response = await get<TFleet>(`fleets/check-invite/${token}`);

    return this.recordResponse(response.data, response.error);
  }
}

export default new FleetsCollection();
