/* eslint-disable @typescript-eslint/no-explicit-any */
export const customQueryOptions = (args: any) => {
  const newKey = args.queryKey
    .filter((part: any) => {
      return typeof part !== "object";
    })
    .join("_");

  const newParams = args.queryKey.filter((part: any) => {
    return typeof part === "object";
  });

  return { ...args, queryKey: [newKey, ...newParams] };
};
/* eslint-enable @typescript-eslint/no-explicit-any */

export default customQueryOptions;
