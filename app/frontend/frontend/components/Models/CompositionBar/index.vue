<script lang="ts">
export default {
  name: "CompositionBar",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";

type Segment = {
  key: string;
  label: string;
  value: number;
  color: string;
};

type Props = {
  segments: Segment[];
  format?: string;
  highlighted?: string | null;
};

const props = withDefaults(defineProps<Props>(), {
  format: "integer",
  highlighted: null,
});

const emit = defineEmits<{ highlight: [key: string | null] }>();

const { t, toNumber } = useI18n();

const round = (value: number) => Math.round(value);
// `toNumber` renders any falsy value as "N/A"; a segment rounding to 0% is a
// real value, not missing data.
const num = (value: number) => (value ? toNumber(value, "integer") : "0");

const rows = computed(() => {
  const total = props.segments.reduce((sum, segment) => sum + segment.value, 0);

  return props.segments.map((segment) => ({
    ...segment,
    pct: total ? (segment.value / total) * 100 : 0,
  }));
});
</script>

<template>
  <div class="composition">
    <div
      class="composition__bar"
      :class="{ 'composition__bar--dimmed': highlighted }"
    >
      <div
        v-for="row in rows"
        :key="row.key"
        class="composition__seg"
        :class="{ 'composition__seg--active': highlighted === row.key }"
        :style="{ width: `${row.pct}%`, background: row.color }"
      />
    </div>
    <div class="composition__legend">
      <div
        v-for="row in rows"
        :key="row.key"
        class="composition__row"
        @mouseenter="emit('highlight', row.key)"
        @mouseleave="emit('highlight', null)"
      >
        <span class="composition__swatch" :style="{ background: row.color }" />
        <span class="composition__label">{{ t(row.label) }}</span>
        <span class="composition__value">
          {{ toNumber(round(row.value), format) }}
        </span>
        <span class="composition__pct"> {{ num(round(row.pct)) }}% </span>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.composition {
  &__bar {
    display: flex;
    height: 16px;
    border-radius: 999px;
    overflow: hidden;
    background: $gray-black;
    border: 1px solid rgba($gray-light, 0.28);
  }

  &__seg {
    height: 100%;
    transition:
      width 0.35s ease,
      opacity 0.18s ease;
  }

  &__bar--dimmed &__seg:not(&__seg--active) {
    opacity: 0.25;
  }

  &__legend {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 4px 22px;
    margin-top: 16px;

    @media (max-width: 576px) {
      grid-template-columns: 1fr;
    }
  }

  &__row {
    display: grid;
    grid-template-columns: auto 1fr auto auto;
    align-items: center;
    gap: 9px;
    padding: 4px 6px;
    border-radius: 6px;
    transition: background 0.15s ease;

    &:hover {
      background: rgba(#fff, 0.03);
    }
  }

  &__swatch {
    width: 9px;
    height: 9px;
    border-radius: 2px;
  }

  &__label {
    font-size: 13px;
    color: $text-color;
  }

  &__value {
    font-weight: 700;
    font-size: 13px;
    color: lighten($text-color, 15%);
    font-variant-numeric: tabular-nums;
  }

  &__pct {
    font-size: 12px;
    color: $gray-light;
    min-width: 42px;
    text-align: right;
    font-variant-numeric: tabular-nums;
  }
}
</style>
