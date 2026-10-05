<script lang="ts">
export default {
  name: "LocationKindIcon",
};
</script>

<script lang="ts" setup>
import { type LocationKindEnum } from "@/services/fyApi";
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { GLYPHS } from "./glyphs";

type Props = {
  kind: LocationKindEnum;
};

const props = defineProps<Props>();

const glyph = computed(() => GLYPHS[props.kind] ?? GLYPHS.other);
</script>

<template>
  <DuotoneGlyph class="location-kind-icon" :glyph="glyph" :data-kind="kind" />
</template>
