<script lang="ts">
export default {
  name: "HangarPlannerShipName",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import type { HangarPlanModel } from "@/services/fyApi";

type Props = {
  ship: Pick<HangarPlanModel, "slug" | "name">;
  // Off inside a button: the button is already the focus stop, and a tap on the
  // name has to reach it.
  focusable?: boolean;
};

withDefaults(defineProps<Props>(), {
  focusable: true,
});
</script>

<template>
  <CatalogueItemPopover
    :item="{ type: 'Model', slug: ship.slug, name: ship.name }"
    :link="false"
    :focusable="focusable"
    :tap-through="!focusable"
  >
    <slot>{{ ship.name }}</slot>
  </CatalogueItemPopover>
</template>
