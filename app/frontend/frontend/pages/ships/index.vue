<script lang="ts">
export default {
  name: "ShipsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
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
import {
  QueryKeysEnum,
  useModelQueries,
} from "@/frontend/composables/useModelQueries";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useModelFilters } from "@/frontend/composables/useModelFilters";

useHangarItems();
useWishlistItems();

const { t } = useI18n();

useMetaInfo();

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

const { modelsQuery } = useModelQueries();

const { perPage, page, updatePerPage } = usePagination(QueryKeysEnum.MODELS);

const { filters } = useModelFilters(() => refetch());

const {
  data: models,
  refetch,
  ...asyncStatus
} = modelsQuery({
  page: page,
  perPage: perPage,
  q: filters,
});

const toggleDetailsTooltip = computed(() => {
  if (detailsVisible.value) {
    return t("actions.hideDetails");
  }

  return t("actions.showDetails");
});
</script>

<template>
  <div class="row">
    <div class="col-12 col-lg-12">
      <div class="row">
        <div class="col-12">
          <h1 class="sr-only">
            {{ t("headlines.ships.index") }}
          </h1>
        </div>
      </div>
    </div>
  </div>

  <Teleport to="#header-actions">
    <Btn
      data-test="model-compare-link"
      :to="{
        name: 'compare-ships',
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
    :records="models?.items || []"
    :async-status="asyncStatus"
  >
    <template #actions-right>
      <BtnDropdown :size="BtnSizesEnum.SMALL">
        <Btn
          :active="detailsVisible"
          :aria-label="toggleDetailsTooltip"
          :size="BtnSizesEnum.SMALL"
          @click="toggleDetails"
        >
          <i class="fad fa-info-square" />
          <span>{{ toggleDetailsTooltip }}</span>
        </Btn>
      </BtnDropdown>
    </template>

    <template #filter>
      <FilterForm />
    </template>

    <template #default="{ records, loading, filterVisible }">
      <Grid
        :records="records"
        :filter-visible="filterVisible"
        primary-key="slug"
      >
        <template #default="{ record }">
          <ModelPanel :model="record" :details="detailsVisible" />
        </template>
      </Grid>

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
  </FilteredList>
</template>
