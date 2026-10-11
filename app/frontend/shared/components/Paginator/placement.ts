import type { InjectionKey } from "vue";

// Set by the list around a paginator that sits above it. The page size is
// chosen once, on the paginator under the list, so the one on top leaves its
// picker out.
export const PAGINATOR_ABOVE_LIST: InjectionKey<boolean> =
  Symbol("paginatorAboveList");
