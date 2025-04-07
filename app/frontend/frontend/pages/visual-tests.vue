<script lang="ts">
export default {
  name: "VisualTestsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingSizeEnum } from "@/shared/components/base/Heading/types";
import { useI18n } from "@/shared/composables/useI18n";

const route = useRoute();

const { t } = useI18n();
</script>

<template>
  <Heading :size="HeadingSizeEnum.HERO" hero
    >Visual Tests {{ t(`headlines.${route.meta?.title}`) }}</Heading
  >

  <router-view />
</template>
