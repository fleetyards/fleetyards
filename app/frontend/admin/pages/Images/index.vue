<template>
  <FilteredList
    :collection="collection"
    :name="$route.name"
    :route-query="$route.query"
    :hash="$route.hash"
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
import ImageUploader from "@/admin/components/ImageUploader/index.vue";
import FilterForm from "@/admin/components/Images/FilterForm/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import imagesCollection, {
  AdminImagesCollection,
} from "@/admin/api/collections/Images";
import { useRoute } from "vue-router";

const collection: AdminImagesCollection = imagesCollection;

const route = useRoute();

const query = computed(() => {
  return route.query.q || {};
});

const galleryId = computed(() => {
  return query.value.galleryIdEq;
});

const galleryType = computed(() => {
  return query.value.galleryTypeEq;
});

const fetch = async () => {
  await collection.refresh();
};
</script>

<script lang="ts">
export default {
  name: "AdminImagesPage",
};
</script>
