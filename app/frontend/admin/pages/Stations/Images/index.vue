<template>
  <ImagesList
    name="admin-station-images"
    gallery-type="Station"
    :gallery-id="galleryId"
  />
</template>

<script lang="ts" setup>
import ImagesList from "@/admin/components/Images/List.vue";
import { useRoute } from "vue-router";

const route = useRoute();

const galleryId = computed(() => {
  return route.params.uuid as string;
});
</script>

<script lang="ts">
export default {
  name: "AdminStationImagesPage",
};
</script>
