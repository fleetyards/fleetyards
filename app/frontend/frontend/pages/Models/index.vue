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
          <Btn
            data-test="fleetchart-link"
            @click.native="modelsStore.toggleFleetchart"
          >
            <i class="fad fa-starship" />
            {{ t("labels.fleetchart") }}
          </Btn>
        </div>
      </div>
    </div>

    <FilteredList
      key="models"
      :collection="collection"
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
            @click.native="modelsStore.toggleDetails"
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

<script lang="ts">
import Vue from "vue";
import { Component, Watch } from "vue-property-decorator";
import { Action, Getter } from "vuex-class";
import Btn from "@/frontend/core/components/Btn/index.vue";
import MetaInfo from "@/frontend/mixins/MetaInfo";
import modelsCollection, {
  ModelsCollection,
} from "@/frontend/api/collections/Models";
import HangarItemsMixin from "@/frontend/mixins/HangarItems";
import BtnDropdown from "@/frontend/core/components/BtnDropdown/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import FilteredGrid from "@/frontend/core/components/FilteredGrid/index.vue";
import ModelPanel from "@/frontend/components/Models/Panel/index.vue";
import ModelsFilterForm from "@/frontend/components/Models/FilterForm/index.vue";
import FleetchartApp from "@/frontend/components/Fleetchart/App/index.vue";

useHangarItems();
useWishlistItems();

  @Getter("detailsVisible", { namespace: "models" }) detailsVisible;

  @Getter("fleetchartVisible", { namespace: "models" }) fleetchartVisible;

  @Getter("perPage", { namespace: "models" }) perPage;

  @Action("toggleDetails", { namespace: "models" }) toggleDetails;

  @Action("toggleFleetchart", { namespace: "models" })
  toggleFleetchart;

  get toggleDetailsTooltip() {
    if (this.detailsVisible) {
      return this.$t("actions.hideDetails");
    }

    return this.$t("actions.showDetails");
  }

  get filters() {
    return {
      filters: this.$route.query.q,
      page: this.$route.query.page,
    };
  }
);
</script>

  @Watch("perPage")
  onPerPageChange() {
    this.collection.findAll(this.filters);
  }
}
</script>
