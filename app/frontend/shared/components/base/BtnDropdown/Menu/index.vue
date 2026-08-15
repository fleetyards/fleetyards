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

.btn-menu {
  @apply absolute hidden min-w-[200px] flex-col;
  @apply bg-control border-edge rounded-control border;
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
.btn-menu :deep(hr) {
  @apply border-edge-soft my-1.5 border-t;
}
</style>
