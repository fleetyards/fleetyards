import { type MaybeRefOrGetter } from "vue";
import { RouteLocationRaw } from "vue-router";

type Props = {
  field: string | number | symbol;
  // Read on every render, not once: a list's default can arrive after its
  // controls do -- the hangar's comes with the signed-in user.
  fallback?: MaybeRefOrGetter<string | undefined>;
  id?: string;
};

export type SortDirection = "asc" | "desc";

const parseFallback = (fallback?: string) => {
  const [column, direction] = (fallback || "").split(" ");

  return {
    column,
    direction: (direction as SortDirection | undefined) || "asc",
  };
};

// Which way `field` is sorted under `sort` (a `"field direction"` pair), or
// under the default when no sort is named.
export const sortDirectionOf = (
  sort: string | undefined,
  field: string,
  fallback?: string,
): SortDirection | undefined => {
  const parsedFallback = parseFallback(fallback);

  if (!sort && parsedFallback.column === field) {
    return parsedFallback.direction;
  }

  const [sortCol, sortDirection] = (sort || "").split(" ");

  if (sortCol === field) {
    return sortDirection as SortDirection;
  }

  return undefined;
};

// Where the next press on `field` goes: none, ascending, descending, then back
// to none, where none is the default.
export const nextSortDirection = (
  active: SortDirection | undefined,
  field: string,
  fallback?: string,
): SortDirection | undefined => {
  const parsedFallback = parseFallback(fallback);

  // The default's own field goes to the default first, then toggles,
  // landing back on the default instead of naming it: a descending default
  // would otherwise go nowhere on its first press, its next step being the
  // reset it already shows.
  if (parsedFallback.column === field) {
    if (!active) {
      return undefined;
    }

    const next = active === "asc" ? "desc" : "asc";

    return next === parsedFallback.direction ? undefined : next;
  }

  if (active === "asc") {
    return "desc";
  } else if (!active) {
    return "asc";
  }

  return undefined;
};

// The sort a press on `field` leaves, for a control that keeps its sort
// itself rather than in the URL; undefined is the default.
export const nextSort = (
  sort: string | undefined,
  field: string,
  fallback?: string,
): string | undefined => {
  const direction = nextSortDirection(
    sortDirectionOf(sort, field, fallback),
    field,
    fallback,
  );

  return direction ? `${field} ${direction}` : undefined;
};

export const useTableSorting = ({ field, fallback, id }: Props) => {
  const route = useRoute();

  const currentDirection = computed(() =>
    sortDirectionOf(
      (route.query.s as string) || undefined,
      String(field),
      toValue(fallback),
    ),
  );

  const sortableDirection = () =>
    nextSortDirection(currentDirection.value, String(field), toValue(fallback));

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
