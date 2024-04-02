<script lang="ts">
export default {
  name: "SearchPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import SearchPanel from "@/frontend/components/Search/Panel/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import SearchHistory from "@/frontend/components/Search/History/index.vue";
import { Form } from "vee-validate";
import { useRoute } from "vue-router";
import { useI18n } from "@/shared/composables/useI18n";
import { useFilters } from "@/shared/composables/useFilters";
import { type Model, type SearchQuery } from "@/services/fyApi";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useSearchStore } from "@/frontend/stores/search";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";

const form = ref<SearchQuery>({
  search: undefined,
});

const route = useRoute();

const setupSearch = () => {
  searchTerm.value = filters.value?.search;
  refetch();
};

const { filter, filters } = useFilters<SearchQuery>({
  allowedKeys: ["search"],
  updateCallback: setupSearch,
});

const { search: searchService } = useApiClient();

const shareUrl = computed(() => window.location.href);

const { t } = useI18n();

const shareTitle = computed(() =>
  t("labels.search.shareTitle", { query: String(form.value?.search) }),
);

const searchTerm = ref<string | undefined>();

watch(
  () => searchTerm.value,
  () => {
    filter({ search: searchTerm.value });
  },
);

const historyVisible = computed(() => {
  return !searchResults.value?.length && !searchTerm.value;
});

const searchStore = useSearchStore();

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
                    :size="BtnSizesEnum.LARGE"
                    :inline="true"
                    :type="BtnTypesEnum.SUBMIT"
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
              <SearchPanel v-else :item="result" />
            </div>
          </transition-group>
        </template>
      </FilteredList>
    </transition>
  </section>
</template>

<style lang="scss" scoped>
@import "search";
</style>
