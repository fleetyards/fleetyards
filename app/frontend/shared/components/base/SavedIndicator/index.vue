<script lang="ts">
export default {
  name: "SavedIndicator",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

const VISIBLE_FOR_MS = 2000;

const { t } = useI18n();

const visible = ref(false);

let hideTimer: ReturnType<typeof setTimeout> | undefined;

const show = () => {
  clearTimeout(hideTimer);
  visible.value = true;
  hideTimer = setTimeout(() => {
    visible.value = false;
  }, VISIBLE_FOR_MS);
};

onBeforeUnmount(() => clearTimeout(hideTimer));

defineExpose({ show });
</script>

<template>
  <span class="saved-indicator" role="status" data-test="saved-indicator">
    <transition name="fade">
      <span v-if="visible" class="saved-indicator__label">
        <i class="fa-solid fa-check" aria-hidden="true" />
        {{ t("labels.saved") }}
      </span>
    </transition>
  </span>
</template>

<style lang="scss" scoped>
.saved-indicator {
  margin-left: 8px;
  font-size: 0.8em;
  color: var(--color-success);
  white-space: nowrap;
}
</style>
