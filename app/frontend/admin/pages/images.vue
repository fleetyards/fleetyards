<script lang="ts">
export default {
  name: "AdminImagesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import ImagesList from "@/admin/components/Images/List.vue";
import Heading from "@/shared/components/base/Heading/index.vue";

const { t } = useI18n();
</script>

<template>
  <Heading>{{ t("headlines.admin.images.index") }}</Heading>
  <ImagesList filterable />
</template>
