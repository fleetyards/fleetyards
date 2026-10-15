import type { ComputedRef, InjectionKey, Ref } from "vue";

export enum EmptyVariantsEnum {
  DEFAULT = "default",
  BOX = "box",
}

// Whether the list an empty box stands in was narrowed by a filter. Offered by
// FilteredList, which knows the page's view keys; the box cannot tell a filter
// from view state by reading the URL on its own.
export const listFilteredKey = Symbol("listFiltered") as InjectionKey<
  Ref<boolean> | ComputedRef<boolean>
>;
