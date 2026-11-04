<script lang="ts">
export default {
  name: "HangarPlannerHangarFlowCardTitle",
};
</script>

<script lang="ts" setup>
import ShipName from "@/frontend/components/Hangar/Planner/ShipName/index.vue";
import type { HangarPlanModel } from "@/services/fyApi";

type Props = {
  title: string;
  model?: HangarPlanModel;
  // Every ship the card stands for, each with a card of its own.
  ships?: HangarPlanModel[];
  focusable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  model: undefined,
  ships: undefined,
  focusable: true,
});

const names = computed(() =>
  props.ships && props.ships.length > 1
    ? props.ships.map((ship) => ({ ship, label: ship.name }))
    : [{ ship: props.model, label: props.title }],
);
</script>

<template>
  <template v-for="(name, index) in names" :key="index">
    <template v-if="index > 0">{{ " / " }}</template>
    <ShipName v-if="name.ship" :ship="name.ship" :focusable="focusable">
      <span class="hangar-flow-title__name">{{ name.label }}</span>
    </ShipName>
    <template v-else>{{ name.label }}</template>
  </template>
</template>

<style lang="scss" scoped>
// The card's button stretches over the whole card, which would otherwise take
// the hover before the name sees it.
.hangar-flow-title__name {
  position: relative;
  z-index: 1;
}
</style>
