import { type MaybeRefOrGetter } from "vue";
import { RouteLocationRaw } from "vue-router";

type Props = {
  field: string | number | symbol;
  // Read on every render, not once: a list's default can arrive after its
  // controls do -- the hangar's comes with the signed-in user.
  fallback?: MaybeRefOrGetter<string | undefined>;
  id?: string;
};

export const useTableSorting = ({ field, fallback, id }: Props) => {
  const route = useRoute();

  const parsedFallback = computed(() => {
    const [column, direction] = (toValue(fallback) || "").split(" ");

    return {
      column,
      direction: (direction as "asc" | "desc" | undefined) || "asc",
    };
  });

  const currentDirection = computed((): "asc" | "desc" | undefined => {
    const sorts = (route.query.s as string) || "";
    const [sortCol, sortDirection] = sorts.split(" ");

    if (!sorts && parsedFallback.value.column === String(field)) {
      return parsedFallback.value.direction;
    }

    if (sortCol === field) {
      return sortDirection as "asc" | "desc";
    }

    return undefined;
  });

  const sortableDirection = () => {
    const active = currentDirection.value;

    // The default's own field goes to the default first, then toggles,
    // landing back on the default instead of naming it: a descending default
    // would otherwise go nowhere on its first press, its next step being the
    // reset it already shows.
    if (parsedFallback.value.column === String(field)) {
      if (!active) {
        return undefined;
      }

      const next = active === "asc" ? "desc" : "asc";

      return next === parsedFallback.value.direction ? undefined : next;
    }

    if (active === "asc") {
      return "desc";
    } else if (!active) {
      return "asc";
    }

    return undefined;
  };

  // Where the third press goes, after ascending and descending.
  const resetLink = computed(
    () =>
      ({
        query: {
          ...route.query,
          s: undefined,
          page: undefined,
        },
        hash: id ? `#${id}` : undefined,
      }) as RouteLocationRaw,
  );

  const sortableLink = computed(() => {
    const direction = sortableDirection();

    if (!direction) {
      return resetLink.value;
    }

    return {
      query: {
        ...route.query,
        s: `${String(field)} ${direction}`,
        page: undefined,
      },
      hash: id ? `#${id}` : undefined,
    } as RouteLocationRaw;
  });

  return {
    currentDirection,
    sortableLink,
    resetLink,
  };
};
