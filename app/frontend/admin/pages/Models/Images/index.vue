<template>
  <FilteredList
    :collection="collection"
    collection-method="findAllForGallery"
    :name="route.name || 'model-images'"
    :route-query="route.query"
    :hash="route.hash"
    :params="routeParams"
    :paginated="true"
    class="images"
  >
    <template #default="{ records, loading }">
      <ImageUploader
        :loading="loading"
        :images="records"
        :gallery-id="galleryId"
        gallery-type="Model"
        @image-deleted="fetch"
        @image-uploaded="fetch"
      />
    </template>
  </FilteredList>
</template>

<script lang="ts" setup>
import { useRoute } from "vue-router/composables";
import ImageUploader from "@/admin/components/ImageUploader/index.vue";
import FilteredList from "@/frontend/core/components/FilteredList/index.vue";
import imagesCollection, {
  AdminImagesCollection,
} from "@/admin/api/collections/Images";

const collection: AdminImagesCollection = imagesCollection;

const route = useRoute();

const galleryId = computed(() => route.params.uuid);

const routeParams = computed(() => ({
  galleryType: "models",
  galleryId: galleryId.value,
}));

const filters = computed(() => ({
  ...routeParams.value,
  page: route.query.page,
}));

const fetch = async () => {
  await collection.findAllForGallery(filters.value);
};
</script>

<script lang="ts">
export default {
  name: "AdminModelImages",
};
</script>
