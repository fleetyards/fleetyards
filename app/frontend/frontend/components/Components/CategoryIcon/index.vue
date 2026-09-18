<script lang="ts">
export default {
  name: "ComponentCategoryIcon",
};
</script>

<script lang="ts" setup>
import { categoryIcon } from "@/frontend/components/Models/Hardpoints/categoryIcon";

type Props = {
  category?: string | null;
};

const props = defineProps<Props>();

// Resolved once into a local, which is the whole reason this is a component.
// `CategoryIcon` is a discriminated union, and TypeScript cannot narrow it
// across two calls -- a template that asked `categoryIcon(x)?.kind === 'svg'`
// and then read `categoryIcon(x)?.src` was reading `src` off the union.
const icon = computed(() => categoryIcon(props.category));
</script>

<template>
  <!-- An empty span rather than nothing when there is no glyph, so the cells
       below it still line up on one edge. -->
  <img
    v-if="icon?.kind === 'svg'"
    :src="icon.src"
    class="component-category-icon"
    alt=""
  />
  <span
    v-else-if="icon?.kind === 'fa'"
    class="component-category-icon component-category-icon--glyph"
  >
    <i :class="icon.className" />
  </span>
  <span v-else class="component-category-icon" />
</template>
