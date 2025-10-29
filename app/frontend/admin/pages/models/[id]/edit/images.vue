<script lang="ts">
export default {
  name: "AdminModelImagesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import ImagesList from "@/admin/components/Images/List.vue";
import Heading from "@/shared/components/base/Heading/index.vue";

const { t } = useI18n();

const route = useRoute();

const galleryId = computed(() => {
  return route.params.uuid as string;
});
</script>

<template>
  <Heading>{{ t("headlines.admin.models.images") }}</Heading>
  <form @submit.prevent="onSubmit">
    <FormActions :submitting="submitting" @cancel="onCancel" />
  </form>
  <ImagesList
    name="admin-model-images"
    gallery-type="Model"
    :gallery-id="galleryId"
  />
</template>
