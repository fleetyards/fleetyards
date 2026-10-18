<script lang="ts">
export default {
  name: "LoadoutChanges",
};
</script>

<script lang="ts" setup>
import type { LoadoutMetric } from "@/frontend/composables/useLoadoutMetrics";

type Props = {
  title?: string;
  // Only those that moved, each with its change.
  figures: LoadoutMetric[];
  testId?: string;
};

withDefaults(defineProps<Props>(), {
  title: undefined,
  testId: "loadout-changes",
});
</script>

<template>
  <section class="loadout-changes" :data-test="testId">
    <h4 v-if="title" class="loadout-changes__title">{{ title }}</h4>
    <dl class="loadout-changes__list">
      <div
        v-for="figure in figures"
        :key="figure.key"
        class="loadout-changes__change"
        :data-test="`${testId}-${figure.key}`"
      >
        <dt>{{ figure.label }}</dt>
        <dd>
          {{ figure.unit ? `${figure.value} ${figure.unit}` : figure.value }}
          <span
            class="loadout-changes__delta"
            :class="`loadout-changes__delta--${figure.tone}`"
          >
            {{ figure.deltaLabel }}
          </span>
        </dd>
      </div>
    </dl>
  </section>
</template>

<style lang="scss" scoped>
@import "index";
</style>
