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

/*
 * Btn ships no margin of its own - spacing belongs to the container - so a row
 * of them needs one. Defined here rather than per page: four pages had grown
 * their own copy of this and the pages without one had buttons touching.
 */
.visual-tests :deep(.vt-row) {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}

/*
 * The vertical counterpart, for demos stacked one above the other. A column
 * flex rather than margins on the children: the children are real components
 * and several of them align themselves inside the full width they are given.
 */
.visual-tests :deep(.vt-stack) {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 20px;
}
</style>
