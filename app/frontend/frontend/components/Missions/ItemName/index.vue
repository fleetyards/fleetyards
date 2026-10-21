<script lang="ts">
export default {
  name: "MissionItemName",
};
</script>

<script lang="ts" setup>
import CatalogueItemPopover from "@/frontend/components/CatalogueItemPopover/index.vue";
import { type GameMissionCatalogueItem } from "@/services/fyApi";

type Props = {
  name?: string | null;
  catalogueItem?: GameMissionCatalogueItem | null;
};

defineProps<Props>();
</script>

<!-- The game's own name for the thing, since it can be more specific than the
     catalogue row's; the card opens on the row. -->
<template>
  <CatalogueItemPopover v-if="catalogueItem" :item="catalogueItem">{{
    name || catalogueItem.name
  }}</CatalogueItemPopover>
  <template v-else>{{ name }}</template>
</template>
