<route lang="json">
{
  "name": "search",
  "meta": {
    "title": "search"
  }
}
</route>

<template>
  <section class="container search">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ t("headlines.search") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="row justify-content-center">
          <div class="col-12 col-lg-6">
            <Form class="search-form" @submit="search">
              <div class="form-group">
                <div class="input-group-flex">
                  <FormInput
                    v-model="searchTerm"
                    name="search"
                    size="large"
                    :autofocus="true"
                    :clearable="true"
                    translation-key="search.default"
                    :no-label="true"
                  />

                  <Btn
                    id="search-submit"
                    :aria-label="t('labels.search')"
                    size="large"
                    :inline="true"
                    type="submit"
                  >
                    <i class="fal fa-search" />
                  </Btn>
                </div>
              </div>
            </Form>
          </div>
        </div>
      </div>
    </div>
    <transition name="fade">
      <SearchHistory v-if="historyVisible" @restore="restoreSearch" />

      <FilteredList
        v-else-if="searchResults"
        id="search"
        key="search"
        :records="searchResults"
        :name="route.name?.toString() || ''"
        :async-status="asyncStatus"
      >
        <template #actions>
          <ShareBtn :url="shareUrl" :title="shareTitle" />
        </template>
        <template #default>
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="result in searchResults"
              :key="`${result.type}-${result.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <ModelPanel
                v-if="result.type === 'Model'"
                :model="result.item as Model"
                details
              />
              <StationPanel
                v-else-if="result.type === 'Station'"
                :station="result.item as Station"
              />
              <ShopPanel
                v-else-if="result.type === 'Shop'"
                :shop="result.item as Shop"
              />
              <CelestialObjectsPanel
                v-else-if="result.type === 'CelestialObject'"
                :celestial-object="result.item as CelestialObject"
              />
              <StarsystemPanel
                v-else-if="result.type === 'Starsystem'"
                :starsystem="result.item as Starsystem"
              />
              <ComponentPanel
                v-else-if="result.type === 'Component'"
                :component="result.item as Component"
              />
              <CommodityPanel
                v-else-if="result.type === 'Commodity'"
                :commodity="result.item as Commodity"
              />
              <EquipmentPanel
                v-else-if="result.type === 'Equipment'"
                :equipment="result.item as Equipment"
              />
              <SearchPanel v-else :item="result" />
            </div>
          </transition-group>
        </template>
      </FilteredList>
    </transition>
  </section>
</template>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import SearchPanel from "@/frontend/components/Search/Panel/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import CelestialObjectsPanel from "@/frontend/components/CelestialObjects/Panel/index.vue";
import StarsystemPanel from "@/frontend/components/Starsystems/Panel/index.vue";
import ComponentPanel from "@/frontend/components/Components/Panel/index.vue";
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import ShopPanel from "@/frontend/components/Shops/Panel/index.vue";
import CommodityPanel from "@/frontend/components/Commodities/Panel/index.vue";
import EquipmentPanel from "@/frontend/components/Equipment/Panel/index.vue";
import SearchHistory from "@/frontend/components/Search/History/index.vue";
import { Form } from "vee-validate";
import { useRoute } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import {
  type Station,
  type Model,
  type CelestialObject,
  type Starsystem,
  type SearchQuery,
  type Shop,
  type Component,
  type Commodity,
  type Equipment,
} from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useSearchStore } from "@/frontend/stores/search";

const form = ref<SearchQuery>({
  search: undefined,
});

const route = useRoute();

const { filter, filters } = useFilters<SearchQuery>();

const { search: searchService } = useApiClient();

const shareUrl = computed(() => window.location.href);

const { t } = useI18n();

const shareTitle = computed(() =>
  t("labels.search.shareTitle", { query: String(form.value?.search) }),
);

watch(
  () => filters.value?.search,
  () => {
    setupSearch();
  },
);

const searchTerm = ref<string | undefined>();

watch(
  () => searchTerm.value,
  () => {
    filter({ search: searchTerm.value });
  },
);

const setupSearch = () => {
  searchTerm.value = filters.value?.search;
  refetch();
};

const historyVisible = computed(() => {
  return !searchResults.value?.length && !searchTerm.value;
});

onMounted(() => {
  setupSearch();

  enabled.value = true;
});

const searchStore = useSearchStore();

const enabled = ref(false);

const {
  data: searchResults,
  refetch,
  ...asyncStatus
} = useQuery({
  queryKey: ["search", searchTerm.value],
  queryFn: () =>
    searchService.search({
      q: {
        search: searchTerm.value,
      },
    }),
  enabled: !!searchTerm.value,
});

watch(
  () => searchResults.value,
  () => {
    if (searchTerm.value) {
      searchStore.save({
        search: searchTerm.value,
        createdAt: new Date(),
      });
    }
  },
  { deep: true },
);

const search = (values: SearchQuery) => {
  filter(values);
};

const restoreSearch = (search: string) => {
  filter({ search });
};
</script>

<script lang="ts">
export default {
  name: "SearchPage",
};
</script>

<style lang="scss" scoped>
@import "search";
</style>
