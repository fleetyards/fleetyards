<script lang="ts">
export default {
  name: "AdminVisualTestsPage",
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
  <Heading :size="HeadingSizeEnum.HERO" hero>
    Visual Tests {{ t(`headlines.${route.meta?.title}`) }}
  </Heading>

  <div class="visual-tests">
    <router-view />
  </div>
</template>

<style lang="scss" scoped>
/*
 * The same rhythm and the same helper names as the frontend gallery's host page,
 * deliberately duplicated rather than shared: the two apps have separate
 * entrypoints and stylesheets, and a shared partial for eleven lines would tie
 * them together for no gain. If a third gallery appears, extract it then.
 */
.visual-tests :deep(h2) {
  margin-top: 44px;
}

.visual-tests :deep(h2:first-child) {
  margin-top: 0;
}

.visual-tests :deep(h2 + p) {
  margin-bottom: 16px;
}

.visual-tests :deep(.vt-row) {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 20px;
}

.visual-tests :deep(.vt-stack) {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin-bottom: 20px;
}
</style>
