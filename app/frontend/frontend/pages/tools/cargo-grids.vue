<script lang="ts">
export default {
  name: "ToolsCargoGridsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();

const route = useRoute();
</script>

<template>
  <Heading>{{ t(`headlines.${route.meta.title}`) }}</Heading>
</template>
