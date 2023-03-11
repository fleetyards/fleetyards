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
      :collection="collection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :paginated="true"
    >
      <template slot="actions"
        >x
        <template v-if="!mobile">
          <BtnGroup>
            <Btn
              v-tooltip="t('labels.tradeRoutes.showLatestPrices')"
              :active="!averagePrices"
              size="small"
              variant="dropdown"
              @click.native="showLatestPrices"
            >
              <i class="far fa-sort-amount-down" />
            </Btn>
            <Btn
              v-tooltip="t('labels.tradeRoutes.showAveragePrices')"
              :active="averagePrices"
              size="small"
              variant="dropdown"
              @click.native="showAveragePrices"
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
            >
              <i class="far fa-percent" />
            </Btn>
            <Btn
              :active="sortByStation"
              size="small"
              variant="dropdown"
              :to="sortBy('origin_shop_station_name', 'asc')"
              :exact="true"
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

      <FilterForm slot="filter" />

      <template #default="{ records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <QuickFilter v-if="!mobile" key="quickfilter" />
          <div
            v-for="cargoRoute in records"
            :key="cargoRoute.id"
            class="col-12 fade-list-item cargo-route"
          >
            <div class="row">
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: cargoRoute.origin.slug,
                          },
                        }"
                      >
                        {{ cargoRoute.origin.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ cargoRoute.origin.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      :trade-route="cargoRoute"
                      :average="averagePrices"
                      :available-cargo="availableCargo"
                    />
                  </div>
                </Panel>
              </div>
              <div class="col-12 col-md-4 cargo-route-center">
                <h2 class="text-center">
                  {{ cargoRoute.commodity.name }}
                </h2>
                <i class="fa fa-angle-double-right" />
                <TradeRouteProfit
                  :trade-route="cargoRoute"
                  :average="averagePrices"
                  :available-cargo="availableCargo"
                />
              </div>
              <div class="col-12 col-md-4">
                <Panel :outer-spacing="false">
                  <div class="cargo-route-point">
                    <h3>
                      <router-link
                        :to="{
                          name: 'station',
                          params: {
                            slug: cargoRoute.destination.slug,
                          },
                        }"
                      >
                        {{ cargoRoute.destination.name }}
                      </router-link>
                      <br />
                      <small class="text-muted">
                        {{ cargoRoute.destination.locationLabel }}
                      </small>
                    </h3>
                    <TradeRoutePrice
                      price-type="sell"
                      :trade-route="cargoRoute"
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

<script lang="ts" setup>
import { ref, computed, watch, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router/composables";
import { storeToRefs } from "pinia";
import Btn from "@/frontend/core/components/Btn/index.vue";
import PriceModalBtn from "@/frontend/components/ShopCommodities/PriceModalBtn/index.vue";
import Panel from "@/frontend/core/components/Panel/index.vue";
import { sortBy as querySortBy } from "@/frontend/utils/Sorting";
import type { FleetYardsRoute } from "@/frontend/utils/Sorting";
import tradeRoutesCollection from "@/frontend/api/collections/TradeRoutes";
import type { TradeRoutesCollection } from "@/frontend/api/collections/TradeRoutes";
import modelsApiCollection from "@/frontend/api/collections/Models";
import type { ModelsCollection } from "@/frontend/api/collections/Models";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import BtnGroup from "@/frontend/core/components/BtnGroup/index.vue";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import FilterForm from "@/frontend/components/TradeRoutes/FilterForm/index.vue";
import QuickFilter from "@/frontend/components/TradeRoutes/QuickFilter/index.vue";
import TradeRoutePrice from "@/frontend/components/TradeRoutes/Price/index.vue";
import TradeRouteProfit from "@/frontend/components/TradeRoutes/Profit/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useAppStore } from "@/frontend/stores/App";

const collection: TradeRoutesCollection = tradeRoutesCollection;

const modelsCollection: ModelsCollection = modelsApiCollection;

const averagePrices = ref(false);

const cargoShip = ref<TModel | null>(null);

const appStore = useAppStore();

const { mobile } = storeToRefs(appStore);

const { t, toNumber } = useI18n();

const title = computed(() => {
  if (cargoShip.value) {
    return t("headlines.tools.tradeRoutes.withShip", {
      name: `${cargoShip.value.manufacturer.code} ${cargoShip.value.name}`,
      cargo: toNumber(cargoShip.value.cargo, "cargo"),
    });
  }

  return t("headlines.tools.tradeRoutes.index");
});

const availableCargo = computed(() =>
  cargoShip.value ? cargoShip.value.cargo * 100 : null
);

const route = useRoute();

const sorts = computed(() => (route as FleetYardsRoute).query.q?.sorts || []);

const sortByAveragePercent = computed(
  () =>
    sorts.value.includes("average_profit_per_unit_percent asc") ||
    sorts.value.includes("average_profit_per_unit_percent desc")
);

const sortByPercent = computed(
  () =>
    sorts.value.includes("profit_per_unit_percent asc") ||
    sorts.value.includes("profit_per_unit_percent desc")
);

const sortByAverageProfit = computed(
  () =>
    sorts.value.includes("average_profit_per_unit asc") ||
    sorts.value.includes("average_profit_per_unit desc")
);

const sortByProfit = computed(
  () =>
    sorts.value.includes("profit_per_unit asc") ||
    sorts.value.includes("profit_per_unit desc") ||
    !sorts.value.length
);

const sortByStation = computed(
  () =>
    sorts.value.includes("origin_shop_station_name asc") ||
    sorts.value.includes("origin_shop_station_name desc")
);

const fetchCargoShip = async () => {
  const query = (route as FleetYardsRoute).query.q;

  if (!query || !query.cargoShip) {
    cargoShip.value = null;

    return;
  }

  const response = await modelsCollection.findBySlug(query.cargoShip);

  if ((response as TRecordSuccessResponse<TModel>).data) {
    cargoShip.value = (response as TRecordSuccessResponse<TModel>).data;
  }
};

watch(
  () => route,
  () => {
    fetchCargoShip();
  },
  { deep: true }
);

onMounted(() => {
  averagePrices.value = sortByAverageProfit.value || sortByAveragePercent.value;
  fetchCargoShip();
});

const sortBy = (field: string, direction: "asc" | "desc") =>
  querySortBy(route, field, direction);

const router = useRouter();

const showLatestPrices = () => {
  averagePrices.value = false;

  if (sortByProfit.value || sortByAverageProfit.value) {
    router.push(sortBy("profit_per_unit", "desc")).catch(() => {
      // ignore
    });
  } else if (sortByPercent.value || sortByAveragePercent.value) {
    router.push(sortBy("profit_per_unit_percent", "desc")).catch(() => {
      // ignore
    });
  }
};

const showAveragePrices = () => {
  averagePrices.value = true;

  if (sortByProfit.value || sortByAverageProfit.value) {
    router.push(sortBy("average_profit_per_unit", "desc")).catch(() => {
      // ignore
    });
  } else if (sortByPercent.value || sortByAveragePercent.value) {
    router.push(sortBy("average_profit_per_unit_percent", "desc")).catch(() => {
      // ignore
    });
  }
}
</script>

<script lang="ts">
export default {
  name: "TradeRoutesPage",
};

<script lang="ts">
export default {
  name: "TradeRoutesPage",
};

<style lang="scss" scoped>
@import "index";
</style>
