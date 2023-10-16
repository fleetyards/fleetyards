<template>
  <div
    v-if="habitationCounts?.length"
    class="row"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.station.habs") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div
          v-for="(habs, name) in habitationsByName"
          :key="name"
          class="col-6"
        >
          <div class="metrics-label">{{ name }}:</div>
          <div class="metrics-value">
            {{ habs.length }}x {{ habs[0].typeLabel }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { useI18n } from "@/frontend/composables/useI18n";
import { groupBy } from "@/shared/utils/Array";
import type { Habitation, HabitationCount } from "@/services/fyApi";

type Props = {
  habitations?: Habitation[];
  habitationCounts?: Array<HabitationCount>;
  padding?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  habitations: () => {
    return [];
  },
  habitationCounts: () => {
    return [];
  },
  padding: false,
});

const { t } = useI18n();

const habitationsByName = computed(() => {
  return groupBy(props.habitations, "habitationName");
});
</script>

<script lang="ts">
export default {
  name: "StationsHabitations",
};
</script>
