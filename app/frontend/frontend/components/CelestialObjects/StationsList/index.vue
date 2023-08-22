<template>
  <div id="stations" class="row">
    <div class="col-12 col-lg-6">
      <h2>{{ t("headlines.stations") }}</h2>
    </div>
    <div class="col-12 col-lg-6">
      <Pagination
        :pagination="pagination"
        :per-page="perPage"
        :update-per-page="updatePerPage"
        hash="stations"
      />
    </div>
    <div class="col-12">
      <transition-group name="fade-list" class="row" tag="div" appear>
        <div
          v-for="station in items"
          :key="station.slug"
          class="col-12 fade-list-item"
        >
          <StationPanel :station="station" />
        </div>
      </transition-group>
      <Loader :loading="isLoading" :fixed="true" />
    </div>
    <div class="col-12">
      <Pagination
        :pagination="pagination"
        :per-page="perPage"
        :update-per-page="updatePerPage"
        hash="stations"
      />
    </div>
  </div>
</template>

<script lang="ts" setup>
import StationPanel from "@/frontend/components/Stations/Panel/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useRoute } from "vue-router";
import Pagination from "@/frontend/core/components/Pagination/index.vue";
import { usePagination } from "@/frontend/composables/usePagination";
import { BaseList } from "@/services/fyApi";

const { t } = useI18n();

const { stations: stationsClient } = useApiClient();

const route = useRoute();

const items = computed(() => {
  if (!stations.value) {
    return [];
  }

  return stations.value.items;
});

const {
  isLoading,
  data: stations,
  refetch,
} = useQuery({
  queryKey: ["celestialObjectStations"],
  queryFn: () =>
    stationsClient.list({
      q: {
        celestialObjectEq: route.params.slug,
      },
      page: page.value,
      perPage: perPage.value,
    }),
});

const { perPage, page, pagination, updatePerPage } = usePagination(
  "celestialObjectStations",
  stations as Ref<BaseList>,
  refetch,
);
</script>

<script lang="ts">
export default {
  name: "StationsList",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
