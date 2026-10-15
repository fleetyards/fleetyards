import type { InjectionKey, Ref } from "vue";

export enum EmptyVariantsEnum {
  DEFAULT = "default",
  BOX = "box",
}

// The list an empty box stands in, as FilteredList offers it: whether a filter
// narrowed it, and how to clear that filter without leaving the view. The box
// cannot tell a filter from view state by reading the URL on its own.
export type ListFilterContext = {
  filtered: Readonly<Ref<boolean>>;
  reset: () => Promise<void>;
};

export const listFilterKey = Symbol(
  "listFilter",
) as InjectionKey<ListFilterContext>;
