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
import { useRoute, useRouter } from "vue-router";

type Props = {
  countData: {
    name: string;
    label: string;
    count: number;
  }[];
  filterKey?: string;
  label?: string;
};

const props = withDefaults(defineProps<Props>(), {
  filterKey: undefined,
  label: undefined,
});

const route = useRoute();

const router = useRouter();

const filter = async (filter: string) => {
  if (!props.filterKey) {
    return;
  }
  const query = JSON.parse(JSON.stringify(route.query || {}));

  if ((query[props.filterKey] || []).includes(filter)) {
    const index = query[props.filterKey].findIndex(
      (item: string) => item === filter,
    );
    if (index > -1) {
      query[props.filterKey].splice(index, 1);
    }
  } else {
    if (!query[props.filterKey]) {
      query[props.filterKey] = [];
    }
    query[props.filterKey].push(filter);
  }

  await router.replace({
    name: route.name || "home",
    query,
  });
};

// Binary, so the third state is never reached - which is why Chip takes a state
// rather than a pair of booleans.
const classificationState = (classification: string) => {
  if (!props.filterKey) {
    return ChipStatesEnum.NEUTRAL;
  }

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const classFilter = (route.query as Record<string, any>)[props.filterKey];

  if (classFilter?.includes(classification)) {
    return ChipStatesEnum.INCLUDED;
  }

  return ChipStatesEnum.NEUTRAL;
};
</script>

<template>
  <ChipRow :label="label">
    <transition-group name="chip-fade">
      <Chip
        v-for="classification in countData"
        :key="classification.name"
        :state="classificationState(classification.name)"
        :count="classification.count"
        :disabled="!filterKey"
        @toggle="filter(classification.name)"
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
        @click="filter(classification.name)"
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

<style scoped>
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
