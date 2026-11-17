<script lang="ts">
export default {
  name: "StarmapPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import Starmap from "@/frontend/components/Starmap/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

const { t } = useI18n();
</script>

<template>
  <Heading hero>{{ t("headlines.starmap") }}</Heading>
  <Starmap />
</template>
