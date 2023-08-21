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
          <Btn data-test="fleetchart-link" @click.native="toggleFleetchart">
            <i class="fad fa-starship" />
            {{ t("labels.fleetchart") }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="models"
      :collection="modelsCollection"
      :name="route.name"
      :route-query="route.query"
      :hash="route.hash"
      :paginated="true"
      :hide-loading="fleetchartVisible"
    >
      <template #actions>
        <BtnDropdown size="small">
          <Btn
            :active="detailsVisible"
            :aria-label="toggleDetailsTooltip"
            size="small"
            variant="dropdown"
            @click.native="toggleDetails"
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
          :items="records"
          namespace="models"
          :loading="loading"
          download-name="ships-fleetchart"
        />
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Btn from "@/frontend/core/components/Btn/index.vue";
import modelsCollection from "@/frontend/api/collections/Models";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelsFilterForm from "@/frontend/components/Models/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";
import { useHangarItems } from "@/frontend/composables/useHangarItems";
import { useWishlistItems } from "@/frontend/composables/useWishlistItems";
import { useI18n } from "@/frontend/composables/useI18n";
import Store from "@/frontend/lib/Store";
import type { ModelQuery } from "@/services/fyApi";

useHangarItems();
useWishlistItems();

const { t } = useI18n();

const detailsVisible = computed(() => Store.getters["models/detailsVisible"]);

const fleetchartVisible = computed(
  () => Store.getters["models/fleetchartVisible"]
);

const perPage = computed(() => Store.getters["models/perPage"]);

const toggleDetails = () => {
  Store.dispatch("models/toggleDetails");
};

const toggleFleetchart = () => {
  Store.dispatch("models/toggleFleetchart");
};

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

watch(
  () => perPage.value,
  () => {
    modelsCollection.findAll(filters.value);
  }
);
</script>

<script lang="ts">
export default {
  name: "ModelsPage",
};
</script>
