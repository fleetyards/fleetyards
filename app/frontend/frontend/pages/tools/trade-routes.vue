<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import PriceModalBtn from "@/frontend/components/ShopCommodities/PriceModalBtn/index.vue";
import { sortBy as sortByRoute } from "@/frontend/utils/Sorting";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilterForm from "@/frontend/components/TradeRoutes/FilterForm/index.vue";
import QuickFilter from "@/frontend/components/TradeRoutes/QuickFilter/index.vue";
import TradeRoutePrice from "@/frontend/components/TradeRoutes/Price/index.vue";
import TradeRouteProfit from "@/frontend/components/TradeRoutes/Profit/index.vue";
import Panel from "@/shared/components/Panel/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { TradeRoute } from "@/services/fyApi";
import { useMobile } from "@/shared/composables/useMobile";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";

const mobile = useMobile();

const { t, toNumber } = useI18n();

const averagePrices = ref(false);

const title = computed(() => {
  if (cargoShip.value) {
    return t("headlines.tools.tradeRoutes.withShip", {
      name: `${cargoShip.value.manufacturer?.code} ${cargoShip.value.name}`,
      cargo: toNumber(cargoShip.value.cargo, "cargo"),
    });
  }

  return t("headlines.tools.tradeRoutes.index");
});

const availableCargo = computed(() => {
  return cargoShip.value ? cargoShip.value.metrics.cargo || 0 * 100 : null;
});

const route = useRoute();

const sorts = computed(() => {
  return route.query.q?.sorts || [];
});

const sortByAveragePercent = computed(() => {
  return (
    sorts.value.includes("average_profit_per_unit_percent asc") ||
    sorts.value.includes("average_profit_per_unit_percent desc")
  );
});

const sortByPercent = computed(() => {
  return (
    sorts.value.includes("profit_per_unit_percent asc") ||
    sorts.value.includes("profit_per_unit_percent desc")
  );
});

const sortByAverageProfit = computed(() => {
  return (
    sorts.value.includes("average_profit_per_unit asc") ||
    sorts.value.includes("average_profit_per_unit desc")
  );
});

const sortByProfit = computed(() => {
  return (
    sorts.value.includes("profit_per_unit asc") ||
    sorts.value.includes("profit_per_unit desc") ||
    !sorts.value.length
  );
});

const sortByStation = computed(() => {
  return (
    sorts.value.includes("origin_shop_station_name asc") ||
    sorts.value.includes("origin_shop_station_name desc")
  );
});
const { models: modelsService, tradeRoutes: tradeRoutesService } =
  useApiClient();

const cargoShipSlug = computed(() => {
  return route.query.q?.cargoShip as string;
});

const { data: cargoShip, refetch: refetchCargoShip } = useQuery({
  queryKey: ["cargoShip"],
  queryFn: () => modelsService.model(cargoShipSlug.value),
  enabled: !!cargoShipSlug.value,
});

watch(
  () => cargoShipSlug.value,
  () => {
    refetchCargoShip();
  },
);

const { perPage, page, updatePerPage } = usePagination("tradeRoutes");

const {
  data: tradeRoutes,
  refetch: refetch,
  ...asyncStatus
} = useQuery({
  queryKey: ["tradeRoutes"],
  queryFn: () =>
    tradeRoutesService.tradeRoutes({
      page: page.value,
      perPage: perPage.value,
      q: route.query,
    }),
});

onMounted(() => {
  averagePrices.value = sortByAverageProfit.value || sortByAveragePercent.value;
});

const sortBy = (field: string, direction: string) => {
  return sortByRoute(route, field, direction);
};

const showLatestPrices = () => {
  averagePrices.value = false;

  if (sortByProfit.value || sortByAverageProfit.value) {
    // eslint-disable-next-line @typescript-eslint/no-empty-function
    router.push(sortBy("profit_per_unit", "desc")).catch(() => {});
  } else if (sortByPercent.value || sortByAveragePercent.value) {
    router
      .push(sortBy("profit_per_unit_percent", "desc"))
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(() => {});
  }
};

const router = useRouter();

const showAveragePrices = () => {
  averagePrices.value = true;

  if (sortByProfit.value || sortByAverageProfit.value) {
    router
      .push(sortBy("average_profit_per_unit", "desc"))
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(() => {});
  } else if (sortByPercent.value || sortByAveragePercent.value) {
    router
      .push(sortBy("average_profit_per_unit_percent", "desc"))
      // eslint-disable-next-line @typescript-eslint/no-empty-function
      .catch(() => {});
  }
};
</script>

<script lang="ts">
export default {
  name: "TradeRoutesPage",
};
</script>

<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-md-8">
        <h1>{{ title }}</h1>
      </div>
      <div class="col-12 col-md-4">
        <div class="page-actions page-actions-right">
          <PriceModalBtn
            commodity-item-type="Commodity"
            :withouth-rental="true"
          />
        </div>
      </div>
    </div>
    <FilteredList
      key="tradeRoutes"
      :paginated="true"
      :records="tradeRoutes || []"
      :name="route.name?.toString() || ''"
      :async-status="asyncStatus"
    >
      <template #actions>
        <template v-if="!mobile">
          <BtnGroup>
            <Btn
              v-tooltip="t('labels.tradeRoutes.showLatestPrices')"
              :active="!averagePrices"
              size="small"
              variant="dropdown"
              in-group
              @click="showLatestPrices"
            >
              <i class="far fa-sort-amount-down" />
            </Btn>
            <Btn
              v-tooltip="t('labels.tradeRoutes.showAveragePrices')"
              :active="averagePrices"
              size="small"
              variant="dropdown"
              in-group
              @click="showAveragePrices"
            >
              <i class="far fa-empty-set" />
            </Btn>
          </BtnGroup>
          <BtnGroup>
            <Btn
              v-tooltip="t('labels.tradeRoutes.sortByProfit')"
              :active="sortByProfit || sortByAverageProfit"
              size="small"
              variant="dropdown"
              :to="
                averagePrices
                  ? sortBy('average_profit_per_unit', 'desc')
                  : sortBy('profit_per_unit', 'desc')
              "
              in-group
              :exact="true"
            >
              <i class="far fa-dollar-sign" />
            </Btn>
            <Btn
              v-tooltip="t('labels.tradeRoutes.sortByPercent')"
              :active="sortByPercent || sortByAveragePercent"
              size="small"
              variant="dropdown"
              :to="
                averagePrices
                  ? sortBy('average_profit_per_unit_percent', 'desc')
                  : sortBy('profit_per_unit_percent', 'desc')
              "
              :exact="true"
              in-group
            >
              <i class="far fa-percent" />
            </Btn>
            <Btn
              :active="sortByStation"
              size="small"
              variant="dropdown"
              :to="sortBy('origin_shop_station_name', 'asc')"
              :exact="true"
              in-group
            >
              {{ t("labels.tradeRoutes.sortByStation") }}
            </Btn>
          </BtnGroup>
        </template>
        <BtnDropdown v-else size="small">
          <Btn
            :active="sortByProfit || sortByAverageProfit"
            size="small"
            variant="dropdown"
            :to="
              averagePrices
                ? sortBy('average_profit_per_unit', 'desc')
                : sortBy('profit_per_unit', 'desc')
            "
            :exact="true"
          >
            <i class="far fa-dollar-sign" />
            <span>{{ t("labels.tradeRoutes.sortByProfit") }}</span>
          </Btn>
          <Btn
            :active="sortByPercent || sortByAveragePercent"
            size="small"
            variant="dropdown"
            :to="
              averagePrices
                ? sortBy('average_profit_per_unit_percent', 'desc')
                : sortBy('profit_per_unit_percent', 'desc')
            "
            :exact="true"
          >
            <i class="far fa-percent" />
            <span>{{ t("labels.tradeRoutes.sortByPercent") }}</span>
          </Btn>
          <Btn
            :active="sortByStation"
            size="small"
            variant="dropdown"
            :to="sortBy('origin_shop_station_name', 'asc')"
            :exact="true"
          >
            <i class="fad fa-map-marker-alt" />
            <span>{{ t("labels.tradeRoutes.sortByStation") }}</span>
          </Btn>
        </BtnDropdown>
      </template>

      <template #filter>
        <FilterForm />
      </template>

      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <QuickFilter v-if="!mobile" key="quickfilter" />
          <div
            v-for="tradeRoute in records as TradeRoute[]"
            :key="tradeRoute.id"
            class="col-12 fade-list-item cargo-route"
          >
            <div class="row">
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false" slim>
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: tradeRoute.origin.slug,
                          },
                        }"
                      >
                        {{ tradeRoute.origin.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ tradeRoute.origin.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      :trade-route="tradeRoute"
                      :average="averagePrices"
                      :available-cargo="availableCargo"
                    />
                  </div>
                </Panel>
              </div>
              <div class="col-12 col-md-4 cargo-route-center">
                <h2 class="text-center">
                  {{ tradeRoute.commodity.name }}
                </h2>
                <i class="fa fa-angle-double-right" />
                <TradeRouteProfit
                  :trade-route="tradeRoute"
                  :average="averagePrices"
                  :available-cargo="availableCargo"
                />
              </div>
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false" slim>
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: tradeRoute.destination.slug,
                          },
                        }"
                      >
                        {{ tradeRoute.destination.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ tradeRoute.destination.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      price-type="sell"
                      :trade-route="tradeRoute"
                      :average="averagePrices"
                      :available-cargo="availableCargo"
                    />
                  </div>
                </Panel>
              </div>
            </div>
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<style lang="scss" scoped>
@import "trade-routes";
</style>
