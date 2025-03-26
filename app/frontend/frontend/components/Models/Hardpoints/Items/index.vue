<script lang="ts">
export default {
  name: "HardpointItems",
};
</script>

<script lang="ts" setup>
import { groupBy } from "@/shared/utils/Array";
import HardpointBaseItem from "@/frontend/components/Models/Hardpoints/BaseItem/index.vue";
import HardpointCargoItem from "@/frontend/components/Models/Hardpoints/CargoItem/index.vue";
import HardpointFuelItem from "@/frontend/components/Models/Hardpoints/FuelItem/index.vue";
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

const itemComponent = computed(() => {
  if (props.category === HardpointCategoryEnum.cargogrid) {
    return HardpointCargoItem;
  }
  if (props.category === HardpointCategoryEnum.fueltanks) {
    return HardpointFuelItem;
  }
  if (
    props.category === HardpointCategoryEnum.main_thrusters ||
    props.category === HardpointCategoryEnum.maneuvering_thrusters ||
    props.category === HardpointCategoryEnum.retro_thrusters ||
    props.category === HardpointCategoryEnum.vtol_thrusters
  ) {
    return HardpointThrusterItem;
  }
  if (props.category === HardpointCategoryEnum.seat) {
    return HardpointSeatItem;
  }
  return HardpointBaseItem;
});
</script>

<template>
  <div class="hardpoint-items">
    <Component
      :is="itemComponent"
      v-for="(items, key) in groupedHardpoints"
      :key="key"
      :hardpoints="items"
    />
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
