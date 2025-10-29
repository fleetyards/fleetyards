<script lang="ts">
export default {
  name: "HardpointItemWrapper",
};
</script>

<script lang="ts" setup>
import loadoutListIcon from "@/images/icons/loadout-list-icon.svg";
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
    <div v-if="count" class="hardpoint-item__list">
      <img
        v-if="intended"
        :src="loadoutListIcon"
        class="hardpoint-item__list-icon"
        alt="hardpoint-list-icon"
      />
      <HardpointQuantity :quantity="count" tag="span" />
    </div>
    <div class="hardpoint-item__wrapper">
      <div class="hardpoint-item__inner">
        <slot name="default" />
      </div>
      <slot name="loadout" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
