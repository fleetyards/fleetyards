<script lang="ts">
export default {
  name: "LocationKindIcon",
};
</script>

<script lang="ts" setup>
import { type LocationKindEnum } from "@/services/fyApi";
import { GLYPHS } from "./glyphs";

type Props = {
  kind: LocationKindEnum;
};

const props = defineProps<Props>();

const id = useId();

const glyph = computed(() => {
  const { defs, secondary, primary } = GLYPHS[props.kind] ?? GLYPHS.other;
  const scoped = (markup?: string) => markup?.replaceAll("{id}", id) ?? "";

  return {
    defs: scoped(defs),
    secondary: scoped(secondary),
    primary: scoped(primary),
  };
});
</script>

<template>
  <svg
    class="location-kind-icon"
    viewBox="0 0 512 512"
    aria-hidden="true"
    focusable="false"
    :data-kind="kind"
  >
    <!-- eslint-disable vue/no-v-html -- the glyphs are this component's own constants -->
    <defs v-if="glyph.defs" v-html="glyph.defs" />
    <g class="location-kind-icon__secondary" v-html="glyph.secondary" />
    <g class="location-kind-icon__primary" v-html="glyph.primary" />
    <!-- eslint-enable vue/no-v-html -->
  </svg>
</template>

<style lang="scss" scoped>
// Sized and aligned like a Font Awesome glyph, and coloured through the same
// variables, so it sits beside one and takes the same overrides.
.location-kind-icon {
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
