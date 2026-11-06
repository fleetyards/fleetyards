const isSet = (value: unknown) =>
  value != null &&
  value !== "" &&
  !(Array.isArray(value) && value.every((item) => item == null || item === ""));

// The figures the list is sorted or filtered by, the sort's first: the card
// shows what the list is ordered and narrowed on, as the list view's columns
// would.
export const useListFigures = <Figure extends string>(
  filterKeys: Record<Figure, readonly string[]>,
  sort: () => string | undefined,
) => {
  const route = useRoute();

  return computed<Figure[]>(() => {
    const figures = Object.keys(filterKeys) as Figure[];
    const sortField = sort()?.split(" ")[0];

    const sorted = figures.filter((figure) => figure === sortField);
    const filtered = figures.filter(
      (figure) =>
        figure !== sortField &&
        filterKeys[figure].some((key) => isSet(route.query[key])),
    );

    return [...sorted, ...filtered];
  });
};
