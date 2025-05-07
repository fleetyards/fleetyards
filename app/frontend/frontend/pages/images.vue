<script lang="ts">
export default {
  name: "ImagesPage",
};
</script>

<script lang="ts" setup>
import LazyImage from "@/shared/components/LazyImage/index.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useGallery } from "@/shared/composables/useGallery";
import { usePagination } from "@/shared/composables/usePagination";
import Paginator from "@/shared/components/Paginator/index.vue";
import {
  useImages as useImagesQuery,
  useImagesQueryOptions,
} from "@/services/fyApi";
import { CustomQueryOptions } from "@/services/customQueryOptions";

const { t } = useI18n();

const imagesQueryParams = computed(() => {
  return {
    page: page.value,
    perPage: perPage.value,
  };
});

const imagesQueryKey = computed(() => {
  return (useImagesQueryOptions(imagesQueryParams) as CustomQueryOptions)
    .queryKey;
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
  >
    <template #default="{ records, loading, filterVisible }">
      <Grid
        :records="records"
        :loading="loading"
        :filter-visible="filterVisible"
        primary-key="id"
      >
        <template #default="{ record }">
          <LazyImage
            :src="record.bigUrl"
            :href="record.url"
            :alt="record.name"
            :width="record.width"
            :height="record.height"
            :title="record.name"
            :caption="record.caption"
            shadow
          />
        </template>
      </Grid>
    </template>
    <template #pagination-bottom>
      <Paginator v-if="images" :query-result-ref="images" :per-page="perPage" />
    </template>
  </FilteredList>
</template>
