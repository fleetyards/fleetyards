<script lang="ts">
export default {
  name: "HardpointCategoryIcon",
};
</script>

<script lang="ts" setup>
import DuotoneGlyph from "@/shared/components/DuotoneGlyph/index.vue";
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";

type Props = {
  category?: string | null;
};

const props = defineProps<Props>();

const glyph = computed(() => categoryIcon(props.category));
</script>

<template>
  <!-- The box stays when there is no glyph, so whatever sits beside it still
       lines up on one edge. -->
  <span class="hardpoint-category-icon">
    <DuotoneGlyph v-if="glyph" :glyph="glyph" />
  </span>
</template>

<!-- The size comes in as a custom property rather than a class the caller
     sizes, since a caller's rule and this one would tie on specificity. The
     colour is the caller's: it inherits. -->
<style lang="scss" scoped>
.hardpoint-category-icon {
  --size: var(--hardpoint-category-icon-size, 24px);

  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 1em;
  height: 1em;
  flex: none;
  font-size: var(--size);
  line-height: 1;

  :deep(.duotone-glyph) {
    vertical-align: 0;
  }
}
</style>
