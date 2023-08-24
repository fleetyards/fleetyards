<template>
  <div class="#celestial-objects">
    <div class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="#celestial-objects"
        />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <transition-group name="fade-list" class="row" tag="div" appear>
          <div
            v-for="celestialObject in celestialObjects?.items"
            :key="celestialObject.slug"
            class="col-12 fade-list-item"
          >
            <CelestialObjectItem :item="celestialObject" />
          </div>
        </transition-group>
        <Loader :loading="isLoading" :fixed="true" />
      </div>
    </div>
    <div class="row">
      <div class="col-12">
        <Pagination
          :pagination="pagination"
          :per-page="perPage"
          :update-per-page="updatePerPage"
          hash="#celestial-objects"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import Pagination from "@/shared/components/Paginator/index.vue";
import CelestialObjectItem from "@/frontend/components/CelestialObjects/Item/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";
import { useFyApiClient } from "@/shared/composables/useFyApiClient";
import { useQuery } from "@tanstack/vue-query";
import { usePagination } from "@/shared/composables/usePagination";
import { BaseList } from "@/services/fyApi";

type Props = {
  starsystemSlug: string;
};

const props = defineProps<Props>();

const { currentLocale } = useI18n();

const { celestialObjects: celestialObjectsService } =
  useFyApiClient(currentLocale);

const {
  isLoading,
  data: celestialObjects,
  refetch,
} = useQuery({
  queryKey: ["celestialObjects", props.starsystemSlug],
  queryFn: () =>
    celestialObjectsService.list({
      page: page.value,
      perPage: perPage.value,
      q: {
        parentIdNull: true,
        starsystemEq: props.starsystemSlug,
      },
    }),
});

const { perPage, page, pagination, updatePerPage } = usePagination(
  "celestialObjects",
  celestialObjects as Ref<BaseList>,
  refetch,
);
</script>

<script lang="ts">
export default {
  name: "CelestialObjectsList",
};
</script>
