<script lang="ts">
export default {
  name: "HardpointItemWrapper",
};
</script>

<script lang="ts" setup>
import HardpointQuantity from "@/frontend/components/Models/Hardpoints/Quantity/index.vue";

type Props = {
  count?: number;
  intended?: boolean;
};

withDefaults(defineProps<Props>(), {
  count: undefined,
  intended: false,
});
</script>

<template>
  <div class="hardpoint-item">
    <div class="hardpoint-item__wrapper">
      <div class="hardpoint-item__inner">
        <slot name="default" />
        <HardpointQuantity
          v-if="count && count > 1"
          :quantity="count"
          tag="span"
          class="hardpoint-item__count"
        />
        <slot name="actions" />
      </div>
      <slot name="loadout" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
