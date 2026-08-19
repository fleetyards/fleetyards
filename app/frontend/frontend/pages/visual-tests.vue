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

  <div class="visual-tests">
    <router-view />
  </div>
</template>

<style lang="scss" scoped>
/*
 * Each page is a stack of titled sections. The app's Heading carries no top
 * margin — it is used inside panels, where one would be wrong — so the rhythm
 * between sections belongs to the page that stacks them, not to the heading.
 */
.visual-tests :deep(h2) {
  margin-top: 44px;
}

.visual-tests :deep(h2:first-child) {
  margin-top: 0;
}

/* A section's prose sits under its heading, not adrift between the two. */
.visual-tests :deep(h2 + p) {
  margin-bottom: 16px;
}
</style>
