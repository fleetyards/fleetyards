<script lang="ts">
export default {
  name: "ModelClassLabels",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import ChipRow from "@/shared/components/base/Chip/Row/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import { useFilters } from "@/shared/composables/useFilters";

type Props = {
  countData: {
    name: string;
    label: string;
    count: number;
  }[];
  filterKey?: string;
  /**
   * Query key for the third state. Without it the chip stays binary - in, then
   * out - which is what a consumer whose endpoint has no `notIn` counterpart
   * gets.
   */
  excludeFilterKey?: string;
  label?: string;
  hideLabel?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  filterKey: undefined,
  excludeFilterKey: undefined,
  label: undefined,
  hideLabel: false,
});

// The same composable the group row filters through, rather than a hand-rolled
// router.replace: it drops keys whose array empties and resets the page, so
// clicking a classification and clicking a group now leave the same URL shape.
const { filter, filters } =
  useFilters<Record<string, string | string[] | undefined>>();

const toArray = (value: string | string[] | undefined): string[] => {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return [value];
};

const included = computed(() =>
  props.filterKey ? toArray(filters.value[props.filterKey]) : [],
);

const excluded = computed(() =>
  props.excludeFilterKey ? toArray(filters.value[props.excludeFilterKey]) : [],
);

const filterClassification = (classification: string) => {
  if (!props.filterKey) return;

  if (!props.excludeFilterKey) {
    filter({
      [props.filterKey]: included.value.includes(classification)
        ? included.value.filter((item) => item !== classification)
        : [...included.value, classification],
    });
    return;
  }

  if (included.value.includes(classification)) {
    filter({
      [props.filterKey]: included.value.filter(
        (item) => item !== classification,
      ),
      [props.excludeFilterKey]: [...excluded.value, classification],
    });
    return;
  }

  if (excluded.value.includes(classification)) {
    filter({
      [props.excludeFilterKey]: excluded.value.filter(
        (item) => item !== classification,
      ),
    });
    return;
  }

  filter({ [props.filterKey]: [...included.value, classification] });
};

const classificationState = (classification: string) => {
  if (!props.filterKey) {
    return ChipStatesEnum.NEUTRAL;
  }

  if (included.value.includes(classification)) {
    return ChipStatesEnum.INCLUDED;
  }

  if (excluded.value.includes(classification)) {
    return ChipStatesEnum.EXCLUDED;
  }

  return ChipStatesEnum.NEUTRAL;
};
</script>

<template>
  <ChipRow :label="label" :hide-label="hideLabel">
    <transition-group name="chip-fade">
      <Chip
        v-for="classification in countData"
        :key="classification.name"
        :state="classificationState(classification.name)"
        :count="classification.count"
        :disabled="!filterKey"
        @toggle="filterClassification(classification.name)"
      >
        {{ classification.label }}
      </Chip>
    </transition-group>

    <template #menu>
      <Btn
        v-for="classification in countData"
        :key="`menu-${classification.name}`"
        :active="
          classificationState(classification.name) === ChipStatesEnum.INCLUDED
        "
        @click="filterClassification(classification.name)"
      >
        <Chip
          bare
          :state="classificationState(classification.name)"
          :count="classification.count"
        >
          {{ classification.label }}
        </Chip>
      </Btn>
    </template>
  </ChipRow>
</template>

<style lang="scss" scoped>
/*
 * Local, at 150ms. The global `fade-list` this replaces put `transition: all .5s`
 * on every chip - the 500ms the panel redesign retired - and its enter half never
 * ran at all: the stylesheet still uses Vue 2's `-enter` rather than
 * `-enter-from`.
 */
.chip-fade-enter-active,
.chip-fade-leave-active {
  transition:
    opacity 150ms ease,
    transform 150ms ease;
}

.chip-fade-enter-from,
.chip-fade-leave-to {
  opacity: 0;
  transform: translateY(6px);
}

@media (prefers-reduced-motion: reduce) {
  .chip-fade-enter-active,
  .chip-fade-leave-active {
    transition-duration: 1ms;
  }
}
</style>
