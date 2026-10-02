import type { QueryFunction, UseQueryOptions } from "@tanstack/vue-query";
import { queryClient } from "@/frontend/plugins/QueryClient";

// The generated options are typed for `useQuery`, where `queryFn` carries
// vue-query's widened stand-in for `skipToken` — a bare `symbol` the query
// client's own options reject. Only the key and the fetcher decide what
// `ensureQueryData` returns; the rest of the options still apply at runtime.
export const ensureQueryData = <TData, TError>(
  options: UseQueryOptions<TData, TError, TData>,
): Promise<TData> =>
  queryClient.ensureQueryData(
    options as unknown as {
      queryKey: readonly unknown[];
      queryFn: QueryFunction<TData>;
    },
  );
