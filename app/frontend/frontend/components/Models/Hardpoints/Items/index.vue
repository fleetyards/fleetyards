<script lang="ts">
export default {
  name: "HardpointItems",
};
</script>

<script lang="ts" setup>
import { groupBy, sortBy } from "@/shared/utils/Array";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointCargoItem from "@/frontend/components/Models/Hardpoints/CargoItem/index.vue";
import { type Hardpoint } from "@/services/fyApi";
import { HardpointCategoryEnum } from "@/services/fyAdminApi";

type Props = {
  hardpoints: Hardpoint[];
  category: HardpointCategoryEnum;
};

const props = defineProps<Props>();

const groupByKey = (items: Hardpoint[]) => {
  return groupBy<Hardpoint>(items, "groupKey");
};

const groupedHardpoints = computed(() => {
  if (
    [
      HardpointCategoryEnum.MAIN_THRUSTERS,
      HardpointCategoryEnum.MANEUVERING_THRUSTERS,
    ].includes(props.category)
  ) {
    return groupByComponent(props.hardpoints);
  } else if ([HardpointCategoryEnum.CARGOGRID].includes(props.category)) {
    return groupBy<Hardpoint>(
      sortBy<Hardpoint>(props.hardpoints, "name"),
      "category",
    );
  } else {
    return groupByKey(props.hardpoints);
  }
});

const itemComponent = computed(() => {
  if (props.category === HardpointCategoryEnum.CARGOGRID) {
    return HardpointCargoItem;
  }
  return HardpointItem;
});

const groupByComponent = (list: Hardpoint[]) => {
  return list.reduce(
    (result, item) => {
      const group = item.component?.id as string;
      result[group] = [...(result[group] || [])];
      result[group].push(item);
      return result;
    },
    {} as Record<string, Hardpoint[]>,
  );
};
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
