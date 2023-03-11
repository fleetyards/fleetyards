import { get } from "@/frontend/api/client";
import type { TApiResponse, TApiErrorResponse } from "@/frontend/api/client";

export class StatsCollection {
  quickStats(): Promise<TApiResponse<TQuickStats> | TApiErrorResponse> {
    return get<TQuickStats>("stats/quick-stats");
  }

  modelsByClassification(): Promise<
    TApiResponse<TChartStats[]> | TApiErrorResponse
  > {
    return get<TChartStats[]>("stats/models-by-classification");
  }

  modelsBySize(): Promise<TApiResponse<TChartStats[]> | TApiErrorResponse> {
    return get<TChartStats[]>("stats/models-by-size");
  }

  modelsPerMonth(): Promise<
    TApiResponse<TBarChartStats[]> | TApiErrorResponse
  > {
    return get<TBarChartStats[]>("stats/models-per-month");
  }

  modelsByManufacturer(): Promise<
    TApiResponse<TChartStats[]> | TApiErrorResponse
  > {
    return get<TChartStats[]>("stats/models-by-manufacturer");
  }

  modelsByProductionStatus(): Promise<
    TApiResponse<TChartStats[]> | TApiErrorResponse
  > {
    return get<TChartStats[]>("stats/models-by-production-status");
  }
}

export default new StatsCollection();
