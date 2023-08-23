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
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFyApiClient } from "@/shared/composables/useFyApiClient";
import { useQuery } from "@tanstack/vue-query";
import { useRoute } from "vue-router";
import Pagination from "@/shared/components/Paginator/index.vue";
import { usePagination } from "@/shared/composables/usePagination";
import { BaseList } from "@/services/fyApi";

const { t, currentLocale } = useI18n();

const { stations: stationsService } = useFyApiClient(currentLocale);

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
    stationsService.stations({
      q: {
        celestialObjectEq: route.params.slug?.toString(),
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
