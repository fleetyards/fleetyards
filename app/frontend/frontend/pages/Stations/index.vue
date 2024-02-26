<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1 class="sr-only">
          {{ t("headlines.stations") }}
        </h1>
      </div>
    </div>

    <FilteredList
      key="stations"
      :collection="collection"
      :name="route.name"
      :route-query="$route.query"
      :hash="route.hash"
      :paginated="true"
    >
      <template #filter>
        <FilterForm />
      </template>

      <template #default="{ filterVisible, records }">
        <transition-group name="fade-list" class="row" tag="div" :appear="true">
          <div
            v-for="(record, index) in records"
            :key="`${record.id}-${index}`"
            :class="{
              'col-3xl-6': !filterVisible,
            }"
            class="col-12 fade-list-item"
          >
            <StationPanel :station="record" />
          </div>
        </transition-group>
      </template>
    </FilteredList>
  </section>
</template>

<script lang="ts" setup>
import FilteredList from "@/shared/components/FilteredList/index.vue";
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import FilterForm from "@/frontend/components/Stations/FilterForm/index.vue";
// import stationsCollection from "@/frontend/api/collections/Stations";
// import type { StationsCollection } from "@/frontend/api/collections/Stations";
import { useI18n } from "@/frontend/composables/useI18n";
import { useMetaInfo } from "@/shared/composables/useMetaInfo";

const { t } = useI18n();

useMetaInfo(t);

const route = useRoute();

// const collection: StationsCollection = stationsCollection;
</script>

<script lang="ts">
export default {
  name: "StationsPage",
};
</script>
