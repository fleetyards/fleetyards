<script lang="ts">
export default {
  name: "BtnDropdownMenu",
};
</script>

<script lang="ts" setup>
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";

type Props = {
  visible?: boolean;
  position?: Record<string, string>;
};

withDefaults(defineProps<Props>(), {
  visible: false,
  position: () => ({}),
});

/*
 * The menu is a separate component purely so this provide() does not also reach
 * BtnDropdown's trigger button. provide() applies to every descendant in the
 * component tree, so providing "menu" from BtnDropdown itself would style the
 * trigger as a menu item too.
 *
 * A consequence worth knowing: a BtnDropdown nested inside a BtnGroup still gets
 * "group" for its trigger, because inject() walks the component tree - which is
 * what the old stylesheet hand-coded as `> :deep(.panel-btn-dropdown) > .panel-btn`.
 */
provide(BTN_CONTAINER, {
  container: "menu",
  size: computed(() => undefined),
  block: computed(() => false),
});
</script>

<template>
  <div
    class="btn-menu"
    :class="{ 'btn-menu--visible': visible }"
    :style="position"
    data-test="dropdown-list"
    role="menu"
  >
    <slot />
  </div>
</template>

<!-- Plain CSS, not scss: see the note in Btn/index.vue. -->
<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/*
 * Opaque, unlike a button. --color-control is 0.9, which is right for an in-flow
 * control - a little of the page showing through is harmless there. A menu floats
 * over arbitrary content at z-index 2100, so whatever it covers competes with its
 * labels: a photographic page background behind the fleetchart, row text behind a
 * table's actions. --color-gray-darker is the same colour at full opacity, so the
 * menu reads as the same material without the bleed-through.
 */
.btn-menu {
  @apply absolute hidden min-w-[200px] flex-col;
  @apply bg-gray-darker border-edge rounded-control border;
  z-index: 2100;
  font-size: 1rem;
}

.btn-menu--visible {
  @apply flex;
}

/* Same end-cap treatment as the button and the group, so the popover reads as
   part of the same family. */
.btn-menu::before,
.btn-menu::after {
  content: "";
  position: absolute;
  left: max(10px, 14%);
  right: max(10px, 14%);
  height: 2px;
  @apply bg-endcap rounded-[1px];
}

.btn-menu::before {
  top: -1px;
}

.btn-menu::after {
  bottom: -1px;
}

/* Slot content this component lays out - see the :deep note in Btn/index.vue. */
/*
 * A separator, not a bar. The global `hr` is a 3px rounded $gray fill from the
 * old language, so adding a border-top on top of it drew the line twice - one
 * hairline sitting on a grey slab. This resets the fill and keeps the 1px
 * edge-soft rule the rest of the system divides with, and spans the menu's full
 * width rather than floating inset, matching how a panel heading divides.
 */
.btn-menu :deep(hr) {
  @apply border-edge-soft my-1.5 border-t bg-transparent;
  height: 0;
  border-radius: 0;
  margin-inline: 0;
}
</style>
