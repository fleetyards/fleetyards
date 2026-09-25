import { type MaybeRefOrGetter } from "vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";

export type SortFieldOption = { name: string; label: string };

export type SelectableSortFieldsOptions = {
  // A sort shown whether it was picked or not -- the one the list is in right
  // now. A chip that is chosen but hidden would leave the bar claiming no sort.
  include?: MaybeRefOrGetter<string | undefined>;
  // Ignores the pick, for the places that choose among every sort.
  all?: boolean;
};

/**
 * The sorts a ship list offers as chips: the ones picked in its display
 * options, in the order the options list them.
 */
export const useSelectableSortFields = <T>(
  fields: MaybeRefOrGetter<SortFieldOption[]>,
  picked: MaybeRefOrGetter<string[]>,
  { include, all = false }: SelectableSortFieldsOptions = {},
) =>
  computed<BaseTableCol<T>[]>(() => {
    const included = toValue(include)?.split(" ")[0];
    const chosen = toValue(picked);

    return toValue(fields)
      .filter(({ name }) => all || chosen.includes(name) || name === included)
      .map(({ name, label }) => ({ name, label, sortable: true }));
  });
