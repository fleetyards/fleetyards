<script lang="ts">
export default {
  name: "AdminModelImagesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import ImagesList from "@/admin/components/Images/List.vue";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type ModelExtended } from "@/services/fyAdminApi";

const { t } = useI18n();

type Props = {
  model: ModelExtended;
};

const props = defineProps<Props>();
</script>

<template>
  <Heading>{{ t("headlines.admin.models.images") }}</Heading>

  <ImagesList
    ref="imagesList"
    name="admin-model-images"
    gallery-type="Model"
    :gallery-id="props.model.id"
  />
</template>
