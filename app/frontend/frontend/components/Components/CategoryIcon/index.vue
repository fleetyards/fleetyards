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

<!-- Sized here rather than by whoever renders it. The table tried to do that
     through `:deep()` nested under `.components-table` -- a class no element in
     it actually carries, since the rest are flat BEM children -- so the rule
     matched nothing and this went out at whatever an unsized `img` and an
     inherited font-size came to. -->
<style lang="scss" scoped>
.component-category-icon {
  width: 24px;
  height: 24px;
  flex: none;

  &--glyph {
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    line-height: 1;
    color: var(--color-primary, #428bca);
  }
}
</style>
