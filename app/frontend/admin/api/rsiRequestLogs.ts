import { axiosClient } from "@/services/axiosAdminClient";
import { useQuery, useQueryClient } from "@tanstack/vue-query";

export interface RsiRequestLog {
  id: string;
  url: string;
  resolved: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface RsiRequestLogsResponse {
  items: RsiRequestLog[];
  meta: {
    pagination: {
      currentPage: number;
      totalPages: number;
    };
  };
}

const RSI_REQUEST_LOGS_QUERY_KEY = ["admin", "rsi-request-logs"];

export const fetchRsiRequestLogs = (params?: Record<string, unknown>) =>
  axiosClient<RsiRequestLogsResponse>({
    url: "/rsi-request-logs",
    method: "GET",
    params,
  });

export const resolveRsiRequestLog = (id: string) =>
  axiosClient<RsiRequestLog>({
    url: `/rsi-request-logs/${id}/resolve`,
    method: "PUT",
  });

export const useRsiRequestLogs = (params?: Ref<Record<string, unknown>>) =>
  useQuery({
    queryKey: [...RSI_REQUEST_LOGS_QUERY_KEY, params],
    queryFn: () => fetchRsiRequestLogs(params?.value),
  });

export const useInvalidateRsiRequestLogs = () => {
  const queryClient = useQueryClient();
  return () =>
    queryClient.invalidateQueries({ queryKey: RSI_REQUEST_LOGS_QUERY_KEY });
};
