<template>
  <FilteredList
    :collection="collection"
    name="adminImages"
    :hash="route.hash"
    :paginated="true"
    class="images"
  >
    <template #filter>
      <FilterForm />
    </template>
    <template #default="{ records, loading }">
      <ImageUploader
        :loading="loading"
        :images="records"
        :gallery-id="galleryId"
        :gallery-type="galleryType"
        @image-deleted="fetch"
        @image-uploaded="fetch"
      />
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import { computed } from "vue";
import { useRoute } from "vue-router";
import ImageUploader from "@/admin/components/ImageUploader/index.vue";
import FilterForm from "@/admin/components/Images/FilterForm/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import imagesCollection from "@/admin/api/collections/Images";

const collection = imagesCollection;

const route = useRoute();

const query = computed<GalleryFilter>(() => route.query.q || {});

const galleryId = computed(() => query.value.galleryIdEq);

const galleryType = computed(() => query.value.galleryTypeEq);

const fetch = async () => {
  await collection.refresh();
};
</script>

<script lang="ts">
export default {
  name: "AdminImagesPage",
};
</script>
