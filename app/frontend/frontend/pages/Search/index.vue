<template>
  <section class="container search">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ $t("headlines.search") }}
        </h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <div class="row justify-content-center">
          <div class="col-12 col-lg-6">
            <form class="search-form" @submit.prevent="filter">
              <div class="form-group">
                <div class="input-group-flex">
                  <FormInput
                    id="search"
                    v-model="form.search"
                    size="large"
                    :autofocus="true"
                    :clearable="true"
                    translation-key="search.default"
                    :no-label="true"
                    @clear="filter"
                  />
                  <Btn
                    id="search-submit"
                    :aria-label="$t('labels.search')"
                    size="large"
                    :inline="true"
                    @click.native="search"
                  >
                    <i class="fal fa-search" />
                  </Btn>
                </div>
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
    <transition name="fade">
      <SearchHistory v-if="historyVisible" @restore="restoreSearch" />

      <FilteredList
        v-else
        key="search"
        :collection="collection"
        :name="route.name"
        :route-query="route.query"
        :hash="route.hash"
        :paginated="true"
      >
        <template #actions>
          <ShareBtn :url="shareUrl" :title="shareTitle" />
        </template>
        <template #default="{ records }">
          <transition-group name="fade-list" class="row" tag="div" appear>
            <div
              v-for="result in records"
              :key="`${result.resultType}-${result.id}`"
              class="col-12 col-md-6 col-xxl-4 col-xxlg-2-4 fade-list-item"
            >
              <ModelPanel
                v-if="result.resultType === 'model'"
                :model="result"
                :details="true"
              />
              <CelestialObjectsPanel
                v-else-if="
                  ['celestial_object', 'starsystem'].includes(result.resultType)
                "
                :item="result"
              />
              <ShopCommodityPanel
                v-else-if="result.resultType === 'shop_commodity'"
                :item="result"
              />
              <ComponentPanel
                v-else-if="result.resultType === 'component'"
                :component="result"
              />
              <CommodityPanel
                v-else-if="result.resultType === 'commodity'"
                :commodity="result"
              />
              <EquipmentPanel
                v-else-if="result.resultType === 'equipment'"
                :equipment="result"
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
import { ref, computed, watch } from "vue";
import { useRoute } from "vue-router";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFilters } from "@/frontend/composables/useFilters";
import searchCollection from "@/frontend/api/collections/Search";
import type { SearchCollection } from "@/frontend/api/collections/Search";
import Btn from "@/frontend/core/components/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import SearchPanel from "@/frontend/components/Search/Panel/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import CelestialObjectsPanel from "@/frontend/components/CelestialObjects/Panel/index.vue";
import ShopCommodityPanel from "@/frontend/components/ShopCommodities/Panel/index.vue";
import ComponentPanel from "@/frontend/components/Components/Panel/index.vue";
import CommodityPanel from "@/frontend/components/Commodities/Panel/index.vue";
import EquipmentPanel from "@/frontend/components/Equipment/Panel/index.vue";
import SearchHistory from "@/frontend/components/Search/History/index.vue";
import { useSearchStore } from "@/frontend/stores/Search";

const collection: SearchCollection = searchCollection;

const route = useRoute();

type SearchQuery = {
  search: string;
};

const searchQuery = computed<Partial<SearchQuery>>(() => {
  if (!route.query || !route.query.q) {
    return {};
  }

  return route.query.q as Partial<SearchQuery>;
});

const form = ref<Partial<TSearchFilter>>({
  search: searchQuery.value.search || "",
});

const historyVisible = computed(
  () => !collection.records.length && !form.value.search
);

const filters = computed(() => ({
  filters: route.query.q,
  page: route.query.page || 1,
}));

const firstPage = computed(
  () => !route.query.page || Number(route.query.page) === 1
);

const shareUrl = computed(() => window.location.href);
const { t } = useI18n();

const shareTitle = computed(() => {
  if (!form.value.search) {
    return undefined;
  }

  return t("labels.search.shareTitle", { query: form.value.search });
});

const searchStore = useSearchStore();

const fetch = async () => {
  await collection.findAll(filters.value as unknown as TSearchParams);

  if (collection.records.length && firstPage.value && form.value.search) {
    searchStore.save({
      search: form.value.search,
      createdAt: new Date(),
    });
  }
};

fetch();

watch(
  () => route,
  () => {
    form.value = {
      search: searchQuery.value.search,
    };

    fetch();
  },
  { deep: true }
);

const { filter } = useFilters();

const search = () => {
  filter();
};

const restoreSearch = (search: string) => {
  form.value.search = search;
  filter();
};
</script>

<script lang="ts">
export default {
  name: "SearchPage",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
