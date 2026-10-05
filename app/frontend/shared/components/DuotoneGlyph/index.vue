<script lang="ts">
export default {
  name: "DuotoneGlyph",
};
</script>

<script lang="ts" setup>
import type { Glyph } from "./glyph";

type Props = {
  glyph: Glyph;
};

const props = defineProps<Props>();

const id = useId();

const layers = computed(() => {
  const scoped = (markup?: string) => markup?.replaceAll("{id}", id) ?? "";

  return {
    defs: scoped(props.glyph.defs),
    secondary: scoped(props.glyph.secondary),
    primary: scoped(props.glyph.primary),
  };
});
</script>

<template>
  <svg
    class="duotone-glyph"
    viewBox="0 0 512 512"
    aria-hidden="true"
    focusable="false"
  >
    <!-- eslint-disable vue/no-v-html -- glyphs are constants in the codebase, never user input -->
    <defs v-if="layers.defs" v-html="layers.defs" />
    <g class="duotone-glyph__secondary" v-html="layers.secondary" />
    <g class="duotone-glyph__primary" v-html="layers.primary" />
    <!-- eslint-enable vue/no-v-html -->
  </svg>
</template>

<style lang="scss" scoped>
// Sized and aligned like a Font Awesome glyph, and coloured through the same
// variables, so it sits beside one and takes the same overrides.
.duotone-glyph {
  display: inline-block;
  width: 1em;
  height: 1em;
  vertical-align: -0.125em;
  overflow: visible;

  &__secondary {
    fill: var(--fa-secondary-color, currentColor);
    opacity: var(--fa-secondary-opacity, 0.4);
  }

  &__primary {
    fill: var(--fa-primary-color, currentColor);
  }
}
</style>
