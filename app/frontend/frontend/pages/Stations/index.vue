<template>
  <router-view v-if="isSubRoute" />
  <section v-else class="container">
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
      :name="route.name || 'stations'"
      :route-query="route.query"
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
import { computed } from "vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import FilterForm from "@/frontend/components/Stations/FilterForm/index.vue";
import stationsCollection from "@/frontend/api/collections/Stations";
import type { StationsCollection } from "@/frontend/api/collections/Stations";
import { useRoute } from "vue-router/composables";
import { useI18n } from "@/frontend/composables/useI18n";

const collection: StationsCollection = stationsCollection;

const route = useRoute();

const { t } = useI18n();

const isSubRoute = computed(() => route.name !== "stations");
</script>

<script lang="ts">
export default {
  name: "StationsPage",
};
</script>
