<script lang="ts">
export default {
  name: "CompareModelsSection",
};
</script>

<script lang="ts" setup>
import Collapsed from "@/shared/components/Collapsed.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  id: string;
  title: string;
  collapsed?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  collapsed: false,
});

const { t } = useI18n();

const visible = ref(!props.collapsed);

const toggle = () => {
  visible.value = !visible.value;
};
</script>

<template>
  <MetricsCard :title="title" class="compare-section">
    <template #head>
      <button
        type="button"
        class="compare-section__toggle"
        :class="{ 'compare-section__toggle--open': visible }"
        :aria-expanded="visible"
        :aria-controls="id"
        :aria-label="t('labels.compare.toggleSection', { section: title })"
        @click="toggle"
      >
        <i class="fa fa-chevron-right" />
      </button>
    </template>
    <Collapsed :id="id" :visible="visible" class="compare-matrix">
      <slot />
    </Collapsed>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "@/frontend/components/Compare/compareGrid";

.compare-section {
  // The matrix rows carry their own vertical rhythm, so the card body only needs
  // to keep them clear of the head.
  :deep(.metrics-card__body) {
    padding: 8px 18px 14px;
  }

  // The card is as wide as the matrix, so the default `space-between` head would
  // park the toggle thousands of pixels off screen. Keep it next to the title.
  :deep(.metrics-card__head) {
    justify-content: flex-start;
    gap: 16px;
  }
}

.compare-section__toggle {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  padding: 0;
  background: transparent;
  color: $gray-light;
  border: 1px solid rgba($gray-light, 0.5);
  border-radius: 50%;
  cursor: pointer;
  transition: all 0.15s ease;

  &:hover {
    color: lighten($text-color, 15%);
    border-color: $primary;
  }

  i {
    font-size: 12px;
    transition: transform 0.3s ease;
  }

  &--open i {
    transform: rotate(90deg);
  }
}
</style>
