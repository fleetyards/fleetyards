<template>
  <div class="hardpoint-item">
    <div class="hardpoint-item-quantity">
      {{ hardpoints.length }}
      <span class="text-muted">x</span>
    </div>
    <div class="hardpoint-item-slots">
      <div
        v-for="(itemsByKey, key) in groupByCategory(hardpoints)"
        :key="`${key}`"
        class="hardpoint-item-slot"
      >
        <HardpointItem :hardpoint="itemsByKey[0]" />
        <HardpointLoadout :hardpoint="itemsByKey[0]" />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import { groupBy } from "@/frontend/utils/Helpers";
import HardpointItem from "../Item/index.vue";
import HardpointLoadout from "../Loadout/index.vue";

type Props = {
  hardpoints: TModelHardpoint[];
};

defineProps<Props>();

const groupByCategory = (hardpoints: TModelHardpoint[]) => {
  return groupBy(hardpoints, "category");
};
</script>

<script lang="ts">
export default {
  name: "HardpointGroup",
};
</script>
