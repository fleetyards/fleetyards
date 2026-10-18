<script lang="ts">
export default {
  name: "HardpointItems",
};
</script>

<script lang="ts" setup>
import { groupBy } from "@/shared/utils/Array";
import { groupByHoldName } from "@/shared/utils/CargoHolds";
import { groupIntoStacks } from "@/frontend/components/Models/Hardpoints/stacks";
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointModuleItem from "@/frontend/components/Models/Hardpoints/ModuleItem/index.vue";
import { type Hardpoint } from "@/services/fyApi";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  hardpoints: Hardpoint[];
  category: HardpointCategoryEnum;
};

const props = defineProps<Props>();

const groupedHardpoints = computed(() => {
  return groupIntoStacks(props.hardpoints);
});

type HoldGroupEntry = {
  groupKey: string;
  name: string;
  hardpoints: Hardpoint[];
};

const cargoHoldGroups = computed(() => {
  if (props.category !== HardpointCategoryEnum.CARGOGRID) return null;

  const byGroupKey = groupBy<Hardpoint>(props.hardpoints, "groupKey");
  const entries: HoldGroupEntry[] = Object.entries(byGroupKey).map(
    ([key, items]) => ({
      groupKey: key,
      name: items[0].component?.name || items[0].component?.scKey || "",
      hardpoints: items,
    }),
  );

  return groupByHoldName(entries, (e) => e.name);
});

// A module slot opens the module picker; every other kind of hardpoint is a
// part's row, which draws what its kind shows differently.
const itemComponent = computed(() =>
  props.category === HardpointCategoryEnum.MODULE
    ? HardpointModuleItem
    : HardpointBaseItem,
);
</script>

<template>
  <div class="hardpoint-items">
    <template v-if="cargoHoldGroups">
      <div
        v-for="holdGroup in cargoHoldGroups"
        :key="holdGroup.key"
        class="hardpoint-items__hold-group"
      >
        <div
          v-if="cargoHoldGroups.length > 1"
          class="hardpoint-items__hold-group-label"
        >
          {{ holdGroup.label }}
        </div>
        <HardpointBaseItem
          v-for="entry in holdGroup.items"
          :key="entry.groupKey"
          :hardpoints="entry.hardpoints"
        />
      </div>
    </template>
    <template v-else>
      <Component
        :is="itemComponent"
        v-for="(items, key) in groupedHardpoints"
        :key="key"
        :hardpoints="items"
      />
    </template>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
