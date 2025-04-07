/* eslint-disable @typescript-eslint/no-explicit-any */
export type CustomQueryOptions = {
  queryKey: readonly any[];
  queryFn?: any;
};

export const customQueryOptions = (args: CustomQueryOptions) => {
  return {
    ...args,
    queryKey: transformQueryKey(args.queryKey),
  } as CustomQueryOptions;
};

export const transformQueryKey = (key: readonly any[]) => {
  const newKey = key
    .filter((part: any) => {
      return typeof part !== "object";
    })
    .join("_");

  const newParams = key.filter((part: any) => {
    return typeof part === "object";
  });

  return [newKey, ...newParams];
};
/* eslint-enable @typescript-eslint/no-explicit-any */

export default customQueryOptions;
