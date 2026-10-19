<script lang="ts">
export default { name: "ActiveFilters" };
</script>

<script lang="ts" setup>
import Chip from "@/shared/components/base/Chip/index.vue";
import type { ActiveFilter } from "./types";
import { useI18n } from "@/shared/composables/useI18n";

const props = withDefaults(
  defineProps<{
    filters: ActiveFilter[];
    expanded?: boolean;
  }>(),
  { expanded: false },
);
const emit = defineEmits<{ open: [] }>();
const { t } = useI18n();
const visibleFilters = computed(() =>
  props.expanded ? props.filters : props.filters.slice(0, 2),
);
</script>

<template>
  <div
    v-if="filters.length"
    class="active-filters"
    :class="{ 'active-filters--expanded': expanded }"
    :aria-label="t('filteredList.selected')"
  >
    <Chip
      v-for="item in visibleFilters"
      :key="item.id"
      v-tooltip="{
        content: t('filteredList.remove', { filter: item.label }),
        multiline: true,
      }"
      :toggleable="false"
      class="active-filters__chip"
      @toggle="item.remove()"
    >
      <span class="active-filters__label" aria-hidden="true">{{
        item.label
      }}</span>
      <span class="sr-only">{{
        t("filteredList.remove", { filter: item.label })
      }}</span>
    </Chip>
    <Chip
      v-if="!expanded && filters.length > visibleFilters.length"
      :toggleable="false"
      class="active-filters__more"
      @toggle="emit('open')"
    >
      {{
        t("filteredList.more", {
          count: filters.length - visibleFilters.length,
        })
      }}
    </Chip>
  </div>
</template>

<style lang="scss" scoped>
.active-filters {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
  margin-bottom: 16px;

  &__chip {
    min-width: 0;
    max-width: 38%;

    :deep(.chip__toggle) {
      min-width: 0;
    }
    :deep(.chip__label) {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      min-width: 0;
    }
  }

  &__label {
    // Preserve glyphs extending beyond the chip's tight line box.
    padding-block: 0.15em;
    margin-block: -0.15em;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__more {
    flex-shrink: 0;
  }

  &--expanded {
    flex-wrap: wrap;
    .active-filters__chip {
      max-width: 100%;
    }
  }
}

@media (max-width: $desktop-breakpoint) {
  .active-filters:not(.active-filters--expanded) {
    display: none;
  }
}
</style>
