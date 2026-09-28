import { useModel } from "@/services/fyApi";

/**
 * The ship a pilot picked in the missions filter form. It marks the contracts
 * it can't do rather than narrowing the list, so it lives in the URL as a view
 * key and is read here, never sent with the missions query.
 */
export const useMissionShip = () => {
  const route = useRoute();
  const router = useRouter();

  const shipSlug = computed(() => {
    const value = route.query.ship;

    return typeof value === "string" && value ? value : undefined;
  });

  const { data: ship } = useModel(
    computed(() => shipSlug.value || ""),
    {
      query: { enabled: computed(() => !!shipSlug.value) },
    },
  );

  const setShip = async (slug?: string) => {
    await router.push({
      name: route.name as string,
      query: { ...route.query, page: undefined, ship: slug },
    });
  };

  return { shipSlug, ship, setShip };
};
