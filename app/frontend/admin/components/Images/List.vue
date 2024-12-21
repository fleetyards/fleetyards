<script lang="ts">
export default {
  name: "AdminImagesList",
};
</script>

<script lang="ts" setup>
import ImageUploader from "@/admin/components/ImageUploader/index.vue";
import FilterForm from "@/admin/components/Images/FilterForm/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Paginator from "@/shared/components/Paginator/index.vue";
import { useQuery } from "@tanstack/vue-query";
import { useApiClient } from "@/admin/composables/useApiClient";
import type { ImageQuery } from "@/services/fyAdminApi";
import { usePagination } from "@/shared/composables/usePagination";
import { useImageFilters } from "@/admin/composables/useImageFilters";

type Props = {
  name?: string;
  galleryId?: string;
  galleryType?: string;
  filterable?: boolean;
};

const { isFilterSelected } = useImageFilters();

const props = withDefaults(defineProps<Props>(), {
  name: "admin-images",
  galleryId: undefined,
  galleryType: undefined,
  filterable: false,
});

const route = useRoute();

const routeQuery = computed(() => {
  if (props.galleryId && props.galleryType) {
    return {
      galleryIdEq: props.galleryId,
      galleryTypeEq: props.galleryType,
    } as ImageQuery;
  }

  return (route.query.q || {}) as ImageQuery;
});

const internalGalleryId = computed(() => {
  return props.galleryId || routeQuery.value.galleryIdEq;
});

const internalGalleryType = computed(() => {
  return props.galleryType || routeQuery.value.galleryTypeEq;
});

const { images: imagesService } = useApiClient();

const { data, refetch, ...asyncStatus } = useQuery({
  queryKey: [props.name],
  queryFn: () =>
    imagesService.images({
      page: page.value,
      perPage: perPage.value,
      q: routeQuery.value,
    }),
});

watch(
  () => route.query,
  () => {
    refetch();
  },
  { deep: true },
);

const { perPage, page, updatePerPage } = usePagination(props.name);
</script>

<template>
  <FilteredList
    :id="name"
    :name="name"
    :records="data?.items || []"
    :async-status="asyncStatus"
    primary-key="id"
    class="images"
    :is-filter-selected="isFilterSelected"
  >
    <template v-if="filterable" #filter>
      <FilterForm />
    </template>

    <template #default="{ loading }">
      <ImageUploader
        :loading="loading"
        :images="data?.items || []"
        :gallery-id="internalGalleryId"
        :gallery-type="internalGalleryType"
        @image-deleted="refetch"
        @image-uploaded="refetch"
      />
    </template>
    <template #pagination-bottom>
      <Paginator
        v-if="data"
        :query-result-ref="data"
        :per-page="perPage"
        :update-per-page="updatePerPage"
      />
    </template>
  </FilteredList>
</template>
