<script lang="ts">
export default {
  name: "ImagesPage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import SortBar from "@/shared/components/base/Table/SortBar/index.vue";
import { type BaseTableCol } from "@/shared/components/base/Table/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import GridSkeleton from "@/shared/components/GridSkeleton/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useGallery } from "@/shared/composables/useGallery";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  useImages as useImagesQuery,
  getImagesQueryKey,
} from "@/services/fyApi";

const { t } = useI18n();

// The gallery is only ever cards, so this is the whole sort control. One chip,
// because one is all the endpoint offers a reader: `updatedAt` says when a
// record was touched rather than when the picture arrived, and `enabled` is an
// admin's flag. Pressing it swaps newest for oldest.
const sortFields = computed<BaseTableCol<unknown>[]>(() => [
  { name: "createdAt", label: t("labels.createdAt"), sortable: true },
]);

const imagesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
  };
});

const imagesQueryKey = computed(() => {
  return getImagesQueryKey(imagesQueryParams.value);
});

const { page, perPage } = usePagination(imagesQueryKey);

const { data: images, ...asyncStatus } = useImagesQuery(imagesQueryParams);

useGallery(".images");
</script>

<template>
  <Heading hidden>{{ t("headlines.images") }}</Heading>

  <FilteredList
    name="images"
    :records="images?.items || []"
    :async-status="asyncStatus"
    class="images"
    data-test="images-list"
  >
    <template #skeleton="{ filterVisible }">
      <GridSkeleton variant="image" :filter-visible="filterVisible" />
    </template>

    <template #sort>
      <SortBar :columns="sortFields" default-sort="createdAt desc" />
    </template>

    <template #default="{ records, loading, filterVisible }">
      <!-- Named so a count can target the pictures rather than every link the
           list happens to contain: the test id above sits on the whole
           `FilteredList`, so a paginator or a sort chip counted as an image. -->
      <Grid
        :records="records"
        :loading="loading"
        :filter-visible="filterVisible"
        primary-key="id"
        data-test="images-grid"
      >
        <template #default="{ record }">
          <LazyImage
            :src="record.largeUrl"
            :href="record.url"
            :alt="record.name"
            :width="record.width"
            :height="record.height"
            :title="record.name"
            :caption="record.caption"
            shadow
            gallery
          />
        </template>
      </Grid>
    </template>
    <template #pagination-top>
      <Paginator :query-result-ref="images" :per-page="perPage" />
    </template>
    <template #pagination-bottom>
      <Paginator :query-result-ref="images" :per-page="perPage" />
    </template>
  </FilteredList>
</template>
