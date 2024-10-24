<script lang="ts">
export default {
  name: "ImagesPage",
};
</script>

<script lang="ts" setup>
import GalleryImage from "@/shared/components/Image/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useGallery } from "@/shared/composables/useGallery";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { usePagination } from "@/shared/composables/usePagination";
import { useQuery } from "@tanstack/vue-query";
import Paginator from "@/shared/components/Paginator/index.vue";

const { t } = useI18n();

const { images: imagesService } = useApiClient();

const { page, perPage } = usePagination("images");

const { data: images, ...asyncStatus } = useQuery({
  queryKey: ["images"],
  queryFn: () =>
    imagesService.images({
      page: page.value,
      perPage: perPage.value,
    }),
});

useGallery(".images");
</script>

<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <h1 class="sr-only">
            {{ t("headlines.images") }}
          </h1>
        </div>
      </div>
    </div>
  </div>

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
          <GalleryImage
            :src="record.smallUrl"
            :href="record.url"
            :alt="record.name"
            :width="record.width"
            :height="record.height"
            :title="record.name"
            :caption="record.caption"
          />
        </template>
      </Grid>
    </template>
    <template #pagination-bottom>
      <Paginator v-if="images" :query-result-ref="images" :per-page="perPage" />
    </template>
  </FilteredList>
</template>
