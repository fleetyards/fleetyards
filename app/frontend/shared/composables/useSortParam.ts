/**
 * The sort the list is ordered by, shaped for an API request.
 *
 * The sort lives in the route as `q[s]` -- `SortBar` and the table headings
 * both write it there -- but `useFilters` strips `s` out of `filters`, and a
 * page that builds its request from `filters` (or from nothing but pagination)
 * drops it. The chip then toggles its arrow while the list keeps its old order.
 *
 * `getQuery()` already carries it for pages that have a filter form; this is
 * for the ones that do not.
 */
/**
 * Typed by the caller: each endpoint declares its own sort enum, and the route
 * only ever holds a string. The value reaching here came from a chip or a
 * heading built from that same list, so the cast states what is already true
 * rather than widening anything.
 */
export const useSortParam = <T extends string = string>() => {
  const route = useRoute();

  return computed<{ s?: T }>(() => {
    const sort = route.query.s;

    return sort ? { s: String(sort) as T } : {};
  });
};
