<script lang="ts">
export default {
  name: "HardpointCategoryIcon",
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
  <!-- An empty span rather than nothing when there is no glyph, so whatever
       sits beside it still lines up on one edge. -->
  <img
    v-if="icon?.kind === 'svg'"
    :src="icon.src"
    class="hardpoint-category-icon"
    alt=""
  />
  <span
    v-else-if="icon?.kind === 'fa'"
    class="hardpoint-category-icon hardpoint-category-icon--glyph"
  >
    <i :class="icon.className" />
  </span>
  <span v-else class="hardpoint-category-icon" />
</template>

<!-- The size comes in as a custom property rather than a class the caller
     sizes, since a caller's rule and this one would tie on specificity. The
     colour is the caller's: it inherits. -->
<style lang="scss" scoped>
.hardpoint-category-icon {
  --size: var(--hardpoint-category-icon-size, 24px);

  width: var(--size);
  height: var(--size);
  flex: none;
  object-fit: contain;

  &--glyph {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: calc(var(--size) * 0.75);
    line-height: 1;
  }
}
</style>
