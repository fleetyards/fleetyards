<script lang="ts">
export default {
  name: "CataloguePickerLayout",
};
</script>

<script lang="ts" setup>
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import { EmptyVariantsEnum } from "@/shared/components/Empty/types";
import Loader from "@/shared/components/Loader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";

interface Props {
  countLabel: string;
  loading?: boolean;
  empty?: boolean;
  refreshing?: boolean;
}

withDefaults(defineProps<Props>(), {
  loading: false,
  empty: false,
  refreshing: false,
});

const search = defineModel<string>("search", { default: "" });

const slots = defineSlots<{
  default?: () => unknown;
  filters?: () => unknown;
  moreFilters?: () => unknown;
  summary?: () => unknown;
  notice?: () => unknown;
  more?: () => unknown;
  tray?: () => unknown;
}>();

const { t } = useI18n();

const mobile = useMobile();
</script>

<template>
  <!-- Enter belongs to the search; only the modal's buttons act. -->
  <form
    class="catalogue-picker"
    :class="{
      'catalogue-picker--folded': mobile,
      'catalogue-picker--tray': slots.tray,
    }"
    @submit.prevent
  >
    <div class="catalogue-picker__header">
      <div class="catalogue-picker__toolbar">
        <FormInput
          v-model="search"
          name="catalogue-picker-search"
          class="catalogue-picker__search"
          :label="t('labels.logistics.itemPicker.search')"
          :placeholder="t('labels.logistics.itemPicker.search')"
          icon="fa-light fa-magnifying-glass"
          autofocus
          no-label
          clearable
        />
        <slot name="filters" />
      </div>
      <slot name="moreFilters" />

      <div class="catalogue-picker__summary">
        <span v-if="!loading" class="catalogue-picker__count">
          {{ countLabel }}
        </span>
        <slot name="summary" />
      </div>
      <slot name="notice" />
    </div>

    <Loader v-if="loading" :loading="true" inline />

    <Empty
      v-else-if="empty"
      :variant="EmptyVariantsEnum.DEFAULT"
      inline
      hide-actions
    />

    <div
      v-else
      class="catalogue-picker__grid"
      :class="{ 'catalogue-picker__grid--refreshing': refreshing }"
    >
      <slot />
    </div>

    <div v-if="slots.more" class="catalogue-picker__more">
      <slot name="more" />
    </div>

    <div v-if="slots.tray" class="catalogue-picker__tray">
      <slot name="tray" />
    </div>
  </form>
</template>

<style lang="scss" scoped>
/* The ship picker's layout, for the same reasons: the header and the tray stay
   in view while the grid scrolls between them, so both run out to the flush
   body's edges and are opaque. */
.catalogue-picker {
  padding: 0 var(--modal-gutter, 24px) 24px;
}

.catalogue-picker--tray {
  padding-bottom: 0;
}

.catalogue-picker__header {
  position: sticky;
  top: 0;
  z-index: 3;
  margin: 0 calc(-1 * var(--modal-gutter, 24px));
  padding: 20px var(--modal-gutter, 24px) 0;
  background-color: var(--color-gray-darker, #272b30);
}

.catalogue-picker__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: 0.75rem;
}

.catalogue-picker__search {
  flex: 1;
  min-width: 240px;
}

.catalogue-picker--folded .catalogue-picker__search {
  min-width: 0;
}

.catalogue-picker__summary {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
  padding: 2px 0 12px;
}

.catalogue-picker__count {
  color: var(--color-muted, #7a8288);
  font-size: 13px;
  font-variant-numeric: tabular-nums;
}

.catalogue-picker__grid {
  display: grid;
  gap: 0.75rem;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
}

.catalogue-picker--folded .catalogue-picker__grid {
  grid-template-columns: repeat(
    auto-fill,
    minmax(min(150px, calc((100% - 12px) / 2)), 1fr)
  );
}

.catalogue-picker__grid--refreshing {
  opacity: 0.5;
  pointer-events: none;
  transition: opacity 150ms ease-in-out;
}

.catalogue-picker__more {
  display: flex;
  justify-content: center;
  padding-top: 12px;
}

.catalogue-picker__tray {
  position: sticky;
  bottom: 0;
  z-index: 3;
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  max-height: 84px;
  margin: 12px calc(-1 * var(--modal-gutter, 24px)) 0;
  padding: 12px var(--modal-gutter, 24px);
  overflow-y: auto;
  border-top: 1px solid var(--color-edge-faint, rgb(122 130 136 / 0.16));
  background-color: var(--color-gray-darker, #272b30);
}

@media (prefers-reduced-motion: reduce) {
  .catalogue-picker__grid--refreshing {
    transition-duration: 1ms;
  }
}
</style>
