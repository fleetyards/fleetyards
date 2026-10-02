<script lang="ts">
export default {
  name: "LocationGlobe",
};
</script>

<script lang="ts" setup>
import { globeStyle } from "@/shared/utils/LocationGlobe";

type Props = {
  location: {
    kind?: string;
    color?: string | null;
    bodyType?: string | null;
  };
};

const props = defineProps<Props>();

const style = computed(() => globeStyle(props.location));

// An ordinary moon is cratered like an asteroid; an ordinary planet has
// continents.
const bodyType = computed(
  () =>
    props.location.bodyType ??
    (props.location.kind === "moon" ? "cratered" : "rocky"),
);
</script>

<!-- A body as a lit sphere in its colour. Its surface turns slowly under a
     light that stays put: the surface layer is two tiles wide and slides one
     tile per turn, so the loop has no seam. Size, border and the plain fill a
     body without a colour keeps all come from the caller's class. -->
<template>
  <span
    class="location-globe"
    :class="[
      `location-globe--${bodyType?.replaceAll('_', '-')}`,
      { 'location-globe--lit': style },
    ]"
    :style="style"
    aria-hidden="true"
    data-test="location-globe"
  >
    <template v-if="style">
      <span class="location-globe__surface" />
      <span class="location-globe__shade" />
      <span v-if="bodyType === 'city'" class="location-globe__lights" />
    </template>
  </span>
</template>

<style lang="scss" scoped>
@import "index";
</style>
