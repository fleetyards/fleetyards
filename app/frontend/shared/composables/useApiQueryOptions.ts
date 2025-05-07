import { type CustomQueryOptions } from "@/services/customQueryOptions";
import { UseQueryOptions } from "@tanstack/vue-query";

export const useApiQueryOptions = () => {
  const getQueryKey = <T>(options: UseQueryOptions<T, unknown, unknown>) => {
    return (options as CustomQueryOptions).queryKey;
  };

  return {
    getQueryKey,
  };
};
