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
import { groupBy } from "@/shared/utils/Array";
import HardpointItem from "../Item/index.vue";
import HardpointLoadout from "../Loadout/index.vue";
import type { ModelHardpoint } from "@/services/fyApi";

type Props = {
  hardpoints: ModelHardpoint[];
};

defineProps<Props>();

const groupByCategory = (hardpoints: ModelHardpoint[]) => {
  return groupBy(hardpoints, "category");
};
</script>

<script lang="ts">
export default {
  name: "HardpointItems",
};
</script>
