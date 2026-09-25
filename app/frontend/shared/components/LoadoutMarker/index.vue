<script lang="ts">
export default {
  name: "LoadoutMarker",
};
</script>

<script lang="ts" setup>
import type { VehicleLoadoutMinimal } from "@/services/fyApi";

type Props = {
  loadout: VehicleLoadoutMinimal;
};

defineProps<Props>();
</script>

<template>
  <a
    v-tooltip="loadout.name"
    :aria-label="loadout.name"
    class="loadout-marker"
    :class="{
      'erkul-link': loadout.urlSource === 'erkul',
      'spviewer-link': loadout.urlSource === 'spviewer',
    }"
    :href="loadout.url"
    target="_blank"
    rel="noopener"
    @click.stop
  >
    <template v-if="loadout.urlSource">
      <i />
    </template>
    <template v-else>
      <i class="fa-duotone fa-crosshairs" />
    </template>
  </a>
</template>

<style lang="scss" scoped>
.loadout-marker {
  position: absolute;
  bottom: 50%;
  left: 0;
  transform: translateY(50%);
  width: 40px;
  height: 40px;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: $gray;
  cursor: pointer;

  // Doubled to outrank PanelBody's rounded variants, which round every link
  // inside the body and would round the edge this sits flush against.
  &.loadout-marker {
    border-radius: 0 10px 10px 0;
  }

  i,
  svg {
    color: #fff;
  }
}
</style>
