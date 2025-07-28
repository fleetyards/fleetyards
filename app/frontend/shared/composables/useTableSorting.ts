import { RouteLocationRaw } from "vue-router";

type Props = {
  field: string | number | symbol;
  fallback?: string;
  id?: string;
};

export const useTableSorting = ({ field, fallback, id }: Props) => {
  const route = useRoute();

  const currentDirection = computed((): "asc" | "desc" | undefined => {
    const sorts = (route.query.sorts as string) || "";
    const [sortCol, sortDirection] = sorts.split(" ");

    if (!sorts && fallback && fallback.includes(String(field))) {
      return (fallback.split(" ")[1] as "asc" | "desc") || "asc";
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

  const sortableLink = computed(() => {
    const direction = sortableDirection();

    if (!direction) {
      return {
        query: {
          ...route.query,
          sorts: undefined,
        },
        hash: id ? `#${id}` : undefined,
      } as RouteLocationRaw;
    }

    return {
      query: {
        ...route.query,
        sorts: `${String(field)} ${direction}`,
      },
      hash: id ? `#${id}` : undefined,
    } as RouteLocationRaw;
  });

  return {
    currentDirection,
    sortableLink,
  };
};
