<script lang="ts">
export default {
  name: "LocationKindIcon",
};
</script>

<script lang="ts" setup>
import { type LocationKindEnum } from "@/services/fyApi";
import AppIcon from "@/shared/components/AppIcon/index.vue";
import { GLYPHS } from "./glyphs";

type Props = {
  kind: LocationKindEnum;
};

const props = defineProps<Props>();

const icon = computed(() => GLYPHS[props.kind] ?? GLYPHS.other);
</script>

<template>
  <AppIcon class="location-kind-icon" :icon="icon" :data-kind="kind" />
</template>
