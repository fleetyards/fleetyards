<script lang="ts">
export default {
  name: "AppIcon",
};
</script>

<script lang="ts" setup>
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { type Icon, isGlyph } from "@/shared/components/DuotoneGlyph/glyph";

type Props = {
  icon: Icon;
};

defineProps<Props>();
</script>

<template>
  <DuotoneGlyph v-if="isGlyph(icon)" :glyph="icon" />
  <i v-else :class="icon" />
</template>
