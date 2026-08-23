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
        <div class="hardpoint-item__content">
          <slot name="default" />
        </div>
        <div
          v-if="(count && count > 1) || $slots.actions"
          class="hardpoint-item__rail"
        >
          <HardpointQuantity
            v-if="count && count > 1"
            :quantity="count"
            tag="span"
            class="hardpoint-item__count"
          />
          <slot name="actions" />
        </div>
      </div>
      <slot name="loadout" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
