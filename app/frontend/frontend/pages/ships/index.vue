<script lang="ts">
export default {
  name: "ShipsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelsTable from "@/frontend/components/Models/Table/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import FilterForm from "@/frontend/components/Models/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useI18n } from "@/shared/composables/useI18n";
import { useModelsStore } from "@/frontend/stores/models";
import { storeToRefs } from "pinia";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useModelFilters } from "@/frontend/composables/useModelFilters";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import { useComlink } from "@/shared/composables/useComlink";
import {
  getModelsQueryKey,
  useModels as useModelsQuery,
} from "@/services/fyApi";

useHangarItems();
useWishlistItems();

const { t } = useI18n();

useMetaInfo();

const modelsStore = useModelsStore();
const fleetchartsStore = useFleetchartStore();

const { detailsVisible, gridView } = storeToRefs(modelsStore);

const fleetchartVisible = computed(() => {
  return fleetchartsStore.isVisible("models");
});

const toggleFleetchart = () => {
  fleetchartsStore.toggleFleetchart("models");
};

const modelsQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
    q: filters.value,
  };
});

const modelsQueryKey = computed(() => {
  return getModelsQueryKey(modelsQueryParams);
});

const { perPage, page, updatePerPage } = usePagination(modelsQueryKey);

const { filters, isFilterSelected } = useModelFilters(() => refetch());

const {
  data: models,
  refetch,
  ...asyncStatus
} = useModelsQuery(modelsQueryParams);

const comlink = useComlink();

const openDisplayOptionsModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/DisplayOptionsModal/index.vue"),
  });
};
</script>

<template>
  <Heading hidden>{{ t("headlines.ships.index") }}</Heading>

  <Teleport to="#header-right">
    <Btn
      data-test="model-compare-link"
      :to="{
        name: 'compare',
      }"
      mobile-block
    >
      <i class="fad fa-code-compare" />
      {{ t("actions.compare.ships") }}
    </Btn>
    <Btn data-test="fleetchart-link" mobile-block @click="toggleFleetchart">
      <i class="fad fa-starship" />
      {{ t("labels.fleetchart") }}
    </Btn>
  </Teleport>

  <FilteredList
    name="models"
    :hide-loading="fleetchartVisible"
    :hide-empty-box="!gridView"
    :records="models?.items || []"
    :async-status="asyncStatus"
    :is-filter-selected="isFilterSelected"
  >
    <template #actions-right>
      <Btn
        :aria-label="t('actions.models.openTableConfiguration')"
        :size="BtnSizesEnum.SMALL"
        @click="openDisplayOptionsModal"
      >
        <i class="fad fa-cog" />
      </Btn>
    </template>

    <template #filter>
      <FilterForm />
    </template>

    <template #pagination-top>
      <Paginator
        v-if="models"
        :query-result-ref="models"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #default="{ records, loading, filterVisible, emptyBoxVisible }">
      <Grid
        v-if="gridView"
        :records="records"
        :filter-visible="filterVisible"
        primary-key="slug"
      >
        <template #default="{ record }">
          <ModelPanel :model="record" :details="detailsVisible" />
        </template>
      </Grid>

      <ModelsTable
        v-else
        :loading="loading"
        :empty-box-visible="emptyBoxVisible"
        :models="models?.items || []"
      />

      <FleetchartApp
        :items="models?.items || []"
        namespace="models"
        :loading="loading"
        download-name="ships-fleetchart"
      >
        <template #pagination>
          <Paginator
            v-if="models"
            :query-result-ref="models"
            :per-page="perPage"
            :size="BtnSizesEnum.SMALL"
            :update-per-page="updatePerPage"
          />
        </template>
        <template #filter>
          <FilterForm hide-quicksearch />
        </template>
      </FleetchartApp>
    </template>

    <template #pagination-bottom>
      <Paginator
        v-if="models"
        :query-result-ref="models"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>

    <template #empty="{ hideEmptyBox, emptyBoxVisible }">
      <Empty
        v-if="!hideEmptyBox && emptyBoxVisible"
        :name="t('models.name')"
        :variant="EmptyVariantsEnum.BOX"
      />
    </template>
  </FilteredList>
</template>
