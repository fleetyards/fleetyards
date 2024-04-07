<script lang="ts">
export default {
  name: "ImagesPage",
};
</script>

<script lang="ts" setup>
import Gallery from "@/shared/components/Gallery/index.vue";
import GalleryImage from "@/shared/components/Image/index.vue";
import FilteredList from "@/shared/components/FilteredList/index.vue";
import Grid from "@/shared/components/base/Grid/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useApiClient } from "@/frontend/composables/useApiClient";
import { usePagination } from "@/shared/composables/usePagination";
import { useQuery } from "@tanstack/vue-query";
import Paginator from "@/shared/components/Paginator/index.vue";

const { t } = useI18n();

const gallery = ref<InstanceType<typeof Gallery> | undefined>();

const openGallery = (index: number) => {
  gallery.value?.open(index);
};

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
    <template #default="{ records, loading, filterVisible, primaryKey }">
      <Grid
        :records="records"
        :loading="loading"
        :filter-visible="filterVisible"
        :primary-key="primaryKey"
      >
        <template #default="{ record, index }">
          <GalleryImage
            :src="record.smallUrl"
            :href="record.url"
            :alt="record.name"
            :title="record.caption || record.name"
            @click.prevent.exact="openGallery(index)"
          />
        </template>
      </Grid>
    </template>
    <template #pagination-bottom>
      <Paginator v-if="images" :query-result-ref="images" :per-page="perPage" />
    </template>
  </FilteredList>

  <Gallery ref="gallery" :items="images?.items" />
</template>
