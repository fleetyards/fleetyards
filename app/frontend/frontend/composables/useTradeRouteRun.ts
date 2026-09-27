import { type TradeRouteQuery } from "@/services/fyApi";

export enum TradeRoutePriceAgesEnum {
  DAY = "24",
  THREE_DAYS = "72",
  ANY = "any",
}

const DEFAULT_PRICE_AGE = TradeRoutePriceAgesEnum.THREE_DAYS;

const single = (value: unknown): string | undefined => {
  const first = Array.isArray(value) ? value[0] : value;

  return typeof first === "string" && first ? first : undefined;
};

/**
 * The run a pilot is planning, kept in the URL so a plan can be shared and
 * survives a reload. The page builds its API query from this rather than
 * spreading the route query into `q`: the URL carries view state (the price
 * age's "any", the origin of an ungrouped list) that the API does not accept.
 */
export const useTradeRouteRun = () => {
  const route = useRoute();
  const router = useRouter();

  const modelSlug = computed(() => single(route.query.ship));
  const budget = computed(() => {
    const value = Number(single(route.query.budget));

    return Number.isFinite(value) && value > 0 ? value : undefined;
  });
  const starSystem = computed(() => single(route.query.system));
  const commodity = computed(() => single(route.query.commodity));
  const priceAge = computed(
    () =>
      (single(route.query.priceAge) as TradeRoutePriceAgesEnum | undefined) ||
      DEFAULT_PRICE_AGE,
  );
  // Set from a run's "other places buy it" link: every destination for one
  // commodity bought at one terminal, ungrouped.
  const origin = computed(() => single(route.query.origin));
  const sort = computed(() => single(route.query.s));

  const update = async (changes: Record<string, string | undefined>) => {
    await router.push({
      name: route.name as string,
      query: { ...route.query, ...changes },
    });
  };

  const apiQuery = computed<TradeRouteQuery>(() => {
    const query: TradeRouteQuery = { grouped: !origin.value };

    if (modelSlug.value) query.modelSlug = modelSlug.value;
    if (modelSlug.value && budget.value) query.budget = budget.value;
    if (starSystem.value) query.originTerminalStarSystemIn = [starSystem.value];
    if (commodity.value) query.commoditySlugIn = [commodity.value];
    if (origin.value) query.originTerminalIdIn = [origin.value];
    if (priceAge.value !== TradeRoutePriceAgesEnum.ANY) {
      query.maxPriceAgeHours = Number(priceAge.value);
    }
    if (sort.value) query.s = sort.value as TradeRouteQuery["s"];

    return query;
  });

  return {
    modelSlug,
    budget,
    starSystem,
    commodity,
    priceAge,
    origin,
    sort,
    apiQuery,
    update,
  };
};
