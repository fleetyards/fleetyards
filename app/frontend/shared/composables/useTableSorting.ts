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

  const currentDirection = computed((): "asc" | "desc" | undefined => {
    const sorts = (route.query.s as string) || "";
    const [sortCol, sortDirection] = sorts.split(" ");
    const fallbackSort = toValue(fallback);

    const [fallbackCol, fallbackDirection] = (fallbackSort || "").split(" ");

    if (!sorts && fallbackCol === String(field)) {
      return (fallbackDirection as "asc" | "desc") || "asc";
    }

    if (sortCol === field) {
      return sortDirection as "asc" | "desc";
    }

    return undefined;
  });

  const sortableDirection = () => {
    const active = currentDirection.value;

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
