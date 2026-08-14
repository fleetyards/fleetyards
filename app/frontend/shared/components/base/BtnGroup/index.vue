<script lang="ts">
export default {
  name: "BaseBtnGroup",
};
</script>

<script lang="ts" setup>
import { BTN_CONTAINER } from "@/shared/components/base/Btn/context";
import type { BtnSizesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  /** Set once here instead of on every member. */
  size?: `${BtnSizesEnum}`;
  block?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  size: undefined,
  block: false,
});

// Members read this and drop their own border, radius and end-caps, so this
// component never needs descendant selectors into Btn's internals. The previous
// version carried 118 lines of `> :deep(.panel-btn)` overrides with !important.
provide(BTN_CONTAINER, {
  container: "group",
  size: computed(() => props.size),
  block: computed(() => props.block),
});
</script>

<template>
  <div class="btn-group" :class="{ 'btn-group--block': block }" role="group">
    <div class="btn-group__track">
      <slot />
    </div>
  </div>
</template>

<!-- Plain CSS, not scss: see the note in Btn/index.vue. -->
<style scoped>
@reference "../../../../entrypoints/tailwind.css";

/*
 * The metrics-card__hero pattern: the container owns the border and radius, and
 * the 1px gap lets the container background read as hairline dividers between
 * members. Members are flat fills with no chrome of their own.
 */
.btn-group {
  @apply relative inline-flex;
  @apply border-edge rounded-control border;
  margin: 0;
}

/*
 * The track clips member corners so no member needs to know its position in the
 * group. Relying on :first-child/:last-child instead would break the moment a
 * member is wrapped in another component - a BtnDropdown trigger is the first
 * *and* last child of its own wrapper, so it took a radius on both sides.
 *
 * The clipping lives here rather than on .btn-group because the group's end-caps
 * sit outside its border and overflow:hidden would crop them.
 */
.btn-group__track {
  @apply bg-edge-soft flex items-stretch overflow-hidden;
  gap: 1px;
  width: 100%;
  border-radius: var(--radius-control-inner, 7px);
}

/*
 * One pair of end-caps for the whole control, rather than a pair per member -
 * per-member caps stack hairlines through the middle of the group. This is also
 * why the container cannot use overflow:hidden to clip member corners: it would
 * crop these caps, which sit on the border. Members radius their own end
 * corners instead.
 */
.btn-group::before,
.btn-group::after {
  content: "";
  position: absolute;
  left: max(10px, var(--cap-inset, 12%));
  right: max(10px, var(--cap-inset, 12%));
  height: var(--cap-h-btn, 2px);
  z-index: 2;
  @apply bg-endcap;
}

.btn-group::before {
  top: -1px;
  border-radius: 0 0 var(--cap-r-btn, 1px) var(--cap-r-btn, 1px);
}

.btn-group::after {
  bottom: -1px;
  border-radius: var(--cap-r-btn, 1px) var(--cap-r-btn, 1px) 0 0;
}

.btn-group--block {
  @apply flex w-full;
}

/*
 * A group can contain a plain label segment as well as buttons - the paginator
 * puts its "1 of 9" in a bare span. Give it the same surface as a member,
 * otherwise the track's fill shows straight through and the label reads as a
 * highlighted panel. Direct children only, so .btn__content inside a member is
 * untouched.
 */
.btn-group__track > :deep(span) {
  @apply bg-control text-text flex items-center justify-center px-3.5;
  /* Mirrors .btn--sm's label, since a group with a label segment is a paginator
     and paginators are sm. If Btn's type scale moves, this moves with it - it
     cannot inherit, because size is a per-member prop the group cannot see. */
  @apply text-[15px] leading-tight font-normal whitespace-nowrap;
}
</style>
