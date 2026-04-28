<script lang="ts">
export default {
  name: "HardpointItems",
};
</script>

<script lang="ts" setup>
import { groupBy } from "@/shared/utils/Array";
import { groupByHoldName } from "@/shared/utils/CargoHolds";
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointCargoItem from "@/frontend/components/Models/Hardpoints/CargoItem/index.vue";
import HardpointFuelItem from "@/frontend/components/Models/Hardpoints/FuelItem/index.vue";
import HardpointModuleItem from "@/frontend/components/Models/Hardpoints/ModuleItem/index.vue";
import HardpointThrusterItem from "@/frontend/components/Models/Hardpoints/ThrusterItem/index.vue";
import HardpointSeatItem from "@/frontend/components/Models/Hardpoints/SeatItem/index.vue";
import { type Hardpoint } from "@/services/fyApi";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  hardpoints: Hardpoint[];
  category: HardpointCategoryEnum;
};

const props = defineProps<Props>();

const groupedHardpoints = computed(() => {
  return groupBy<Hardpoint>(props.hardpoints, "groupKey");
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

const itemComponent = computed(() => {
  if (props.category === HardpointCategoryEnum.CARGOGRID) {
    return HardpointCargoItem;
  }
  if (props.category === HardpointCategoryEnum.MODULE) {
    return HardpointModuleItem;
  }
  if (props.category === HardpointCategoryEnum.FUELTANKS) {
    return HardpointFuelItem;
  }
  if (
    props.category === HardpointCategoryEnum.MAIN_THRUSTERS ||
    props.category === HardpointCategoryEnum.MANEUVERING_THRUSTERS ||
    props.category === HardpointCategoryEnum.RETRO_THRUSTERS ||
    props.category === HardpointCategoryEnum.VTOL_THRUSTERS
  ) {
    return HardpointThrusterItem;
  }
  if (props.category === HardpointCategoryEnum.SEAT) {
    return HardpointSeatItem;
  }
  return HardpointBaseItem;
});
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
        <HardpointCargoItem
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
