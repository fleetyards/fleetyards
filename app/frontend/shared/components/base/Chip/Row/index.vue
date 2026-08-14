<script lang="ts">
export default {
  name: "BaseChipRow",
};
</script>

<script lang="ts" setup>
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import { useMobile } from "@/shared/composables/useMobile";

type Props = {
  /** Row title on desktop, dropdown label on mobile - one string, one place. */
  label?: string;
  /**
   * Drops the visible title without dropping the label: the row still names
   * itself to assistive tech, and mobile still labels its dropdown - which
   * otherwise collapses to a bare ellipsis with nothing saying what it filters.
   */
  hideLabel?: boolean;
};

withDefaults(defineProps<Props>(), {
  label: undefined,
  hideLabel: false,
});

const mobile = useMobile();

// Sortable needs a real element to own. The row this replaces gave it a
// `display: contents` wrapper, which has no box at all.
const itemsEl = ref<HTMLElement | null>(null);

defineExpose({ itemsEl });
</script>

<template>
  <BtnDropdown v-if="mobile" class="w-full md:w-auto" data-test="chip-row">
    <!-- Omitted rather than rendered empty, so BtnDropdown's own fallback label
         still applies when a consumer passes no label. -->
    <template v-if="label" #label>
      {{ label }}
    </template>
    <slot name="menu" />
  </BtnDropdown>
  <div
    v-else
    class="chip-row"
    :role="hideLabel && label ? 'group' : undefined"
    :aria-label="hideLabel ? label : undefined"
    data-test="chip-row"
  >
    <h3 v-if="label && !hideLabel" class="chip-row__title">{{ label }}:</h3>
    <div ref="itemsEl" class="chip-row__items">
      <slot />
    </div>
    <slot name="actions" />
  </div>
</template>

<style scoped>
@reference "../../../../../entrypoints/tailwind.css";

/*
 * Two nested flex rows rather than one: the title and the trailing actions belong
 * to the row, while `.chip-row__items` is the box Sortable reorders. Both wrap,
 * so a long list of chips still flows.
 */
.chip-row {
  @apply flex flex-wrap items-center justify-start gap-2;
}

.chip-row__items {
  @apply flex flex-wrap items-center gap-2;
}

/* Keeps h3's own size and weight from typography.scss - only the margins that
   stop it aligning inside a flex row are reset. */
.chip-row__title {
  @apply m-0 leading-none;
}
</style>
