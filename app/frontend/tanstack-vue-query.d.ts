import "@tanstack/vue-query";

// Module augmentation to extend @tanstack/vue-query types
declare module "@tanstack/vue-query" {
  interface UseQueryOptions<
    TQueryFnData = unknown,
    TError = unknown,
    TData = TQueryFnData,
    TQueryKey = unknown[],
  > {
    queryKey: DataTag<QueryKey, TData>;
    enabled?: MaybeRef<boolean>;
    retry?: number | boolean;
    initialData?: MaybeRefDeep<TData | InitialDataFunction<TData> | undefined>;
    overrideQueryKey?: DataTag<QueryKey, TData>;
  }
}

export {};
