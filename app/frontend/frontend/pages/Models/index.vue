<template>
  <section class="container">
    <div class="row">
      <div class="col-12 col-lg-12">
        <div class="row">
          <div class="col-12">
            <h1 class="sr-only">
              {{ t("headlines.models.index") }}
            </h1>
          </div>
        </div>
        <div class="page-actions page-actions-right">
          <Btn
            data-test="model-compare-link"
            :to="{
              name: 'models-compare',
            }"
          >
            <i class="fad fa-code-compare" />
            {{ t("actions.compare.models") }}
          </Btn>
          <Btn data-test="fleetchart-link" @click="toggleFleetchart">
            <i class="fad fa-starship" />
            {{ t("labels.fleetchart") }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="models"
      :paginated="true"
      :hide-loading="fleetchartVisible"
      :records="models?.items || []"
      :name="route.name?.toString() || ''"
      :async-status="asyncStatus"
    >
      <template #actions>
        <BtnDropdown size="small">
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click="toggleDetails"
          >
            <i class="fad fa-info-square" />
            <span>{{ toggleDetailsTooltip }}</span>
          </Btn>
        </BtnDropdown>
      </template>
      <template #filter>
        <ModelsFilterForm />
      </template>

      <template #default="{ records, loading, filterVisible, primaryKey }">
        <FilteredGrid
          :records="records"
          :filter-visible="filterVisible"
          :primary-key="primaryKey"
        >
          <template #default="{ record }">
            <ModelPanel :model="record" :details="detailsVisible" />
          </template>
        </FilteredGrid>

        <FleetchartApp
          :items="models?.items || []"
          namespace="models"
          :loading="loading"
          download-name="ships-fleetchart"
        />
      </template>
      <template #pagination-bottom>
        <Paginator
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
        />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import FilteredGrid from "@/shared/components/FilteredGrid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelsFilterForm from "@/frontend/components/Models/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useI18n } from "@/frontend/composables/useI18n";
import { type ModelQuery, type BaseList } from "@/services/fyApi";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";

useHangarItems();
useWishlistItems();

const { t } = useI18n();

const modelsStore = useModelsStore();
const fleetchartsStore = useFleetchartStore();

const { detailsVisible } = storeToRefs(modelsStore);

const fleetchartVisible = computed(() => {
  return fleetchartsStore.isVisible("models");
});

const toggleDetails = () => {
  modelsStore.toggleDetails();
};

const toggleFleetchart = () => {
  fleetchartsStore.toggleFleetchart("models");
};

const { models: modelsService } = useApiClient();

const {
  data: models,
  refetch,
  ...asyncStatus
} = useQuery({
  queryKey: ["models"],
  queryFn: () =>
    modelsService.models({
      q: filters.value.filters,
      page: page.value,
      perPage: perPage.value,
    }),
});

const toggleDetailsTooltip = computed(() => {
  if (detailsVisible.value) {
    return t("actions.hideDetails");
  }

  return t("actions.showDetails");
});

const route = useRoute();

const filters = computed(() => ({
  filters: route.query.q as unknown as ModelQuery,
  page: Number(route.query.page),
}));

const { perPage, page, pagination, updatePerPage } = usePagination(
  "models",
  models as Ref<BaseList>,
  refetch,
);

watch(
  () => perPage.value,
  () => {
    refetch();
  },
);

watch(
  () => filters.value,
  () => {
    refetch();
  },
  { deep: true },
);
</script>

<script lang="ts">
export default {
  name: "ModelsPage",
};
</script>
