<script lang="ts">
export default {
  name: "LocationJumpLegend",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import type { JumpStyle } from "./layout";

type Props = {
  // The styles on the page, in this order: solid, dotted, dashed.
  styles: JumpStyle[];
  // Whether the page draws lines or lists chips, so each sample looks like
  // what it explains.
  lines: boolean;
};

const props = defineProps<Props>();

const { t } = useI18n();

const ORDER: JumpStyle[] = ["inGame", "temporary", "planned"];

const shown = computed(() =>
  ORDER.filter((style) => props.styles.includes(style)),
);
</script>

<template>
  <ul
    class="location-jump-legend"
    :aria-label="t('labels.location.jumpLegend.title')"
    data-test="jump-legend"
  >
    <li v-for="style in shown" :key="style" class="location-jump-legend__item">
      <svg
        v-if="lines"
        class="location-jump-legend__line"
        :class="`location-jump-legend__line--${style}`"
        viewBox="0 0 28 6"
        aria-hidden="true"
      >
        <line x1="3" y1="3" x2="25" y2="3" />
      </svg>
      <span
        v-else
        class="location-jump-legend__chip"
        :class="`location-jump-legend__chip--${style}`"
        aria-hidden="true"
      />
      {{ t(`labels.location.jumpLegend.${style}`) }}
    </li>
  </ul>
</template>

<style lang="scss" scoped>
// The samples repeat the lane and chip styles at a glance's size.
.location-jump-legend {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 8px 20px;
  margin: 0 0 16px;
  padding: 0;
  list-style: none;
  font-size: 12px;
  color: var(--color-text-dim, #959595);

  &__item {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  &__line {
    width: 28px;
    height: 6px;
    overflow: visible;

    line {
      stroke: var(--color-primary, #428bca);
      stroke-width: 2;
      stroke-linecap: round;
    }

    &--temporary line {
      stroke-dasharray: 0 6;
      stroke-width: 3;
    }

    &--planned line {
      stroke-dasharray: 6 6;
    }
  }

  &__chip {
    width: 20px;
    height: 12px;
    border: 1px solid var(--color-primary, #428bca);
    border-radius: var(--radius-control-bare, 6px);

    &--temporary {
      border-style: dotted;
    }

    &--planned {
      border-style: dashed;
    }
  }
}
</style>
