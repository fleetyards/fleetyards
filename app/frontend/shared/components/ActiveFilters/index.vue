<script lang="ts">
export default { name: "ActiveFilters" };
</script>

<script lang="ts" setup>
import { useResizeObserver } from "@vueuse/core";
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

const root = ref<HTMLElement>();
const measureLayer = ref<HTMLElement>();
const fitCount = ref(1);

const GAP = 8;

// Every chip is rendered once more in an invisible layer, so the row can tell
// how many fit before it shows them. The overflow chip is measured at the
// widest count it can take.
const measure = () => {
  if (props.expanded || !root.value || !measureLayer.value) return;
  const available = root.value.clientWidth;
  const chips = Array.from(
    measureLayer.value.querySelectorAll<HTMLElement>(".active-filters__chip"),
  ).map((chip) => chip.offsetWidth);
  const more =
    measureLayer.value.querySelector<HTMLElement>(".active-filters__more")
      ?.offsetWidth ?? 0;

  let used = 0;
  let count = 0;
  for (const [index, width] of chips.entries()) {
    const next = used + (count ? GAP : 0) + width;
    const rest = index < chips.length - 1 ? GAP + more : 0;
    if (next + rest > available) break;
    used = next;
    count += 1;
  }
  // The first chip shrinks to an ellipsis rather than vanish.
  fitCount.value = Math.max(1, count);
};

useResizeObserver(root, measure);

watch(
  () => [props.filters.map((item) => item.label).join("\n"), props.expanded],
  async () => {
    await nextTick();
    measure();
  },
);

onMounted(measure);

const visibleFilters = computed(() =>
  props.expanded ? props.filters : props.filters.slice(0, fitCount.value),
);
</script>

<template>
  <div
    v-if="filters.length"
    ref="root"
    class="active-filters"
    :class="{ 'active-filters--expanded': expanded }"
    :aria-label="t('filteredList.selected')"
  >
    <div
      v-if="!expanded"
      ref="measureLayer"
      class="active-filters__measure"
      aria-hidden="true"
      inert
    >
      <Chip
        v-for="item in filters"
        :key="item.id"
        :toggleable="false"
        class="active-filters__chip"
      >
        <span class="active-filters__label">{{ item.label }}</span>
        <i class="fa-regular fa-xmark active-filters__remove" />
      </Chip>
      <Chip :toggleable="false" class="active-filters__more">
        {{ t("filteredList.more", { count: filters.length }) }}
      </Chip>
    </div>
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
      <i
        class="fa-regular fa-xmark active-filters__remove"
        aria-hidden="true"
      />
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
  position: relative;
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;

  // Clips the measuring layer, which is as wide as every chip together.
  &:not(&--expanded) {
    overflow: hidden;
  }

  &__measure {
    position: absolute;
    top: 0;
    left: 0;
    display: flex;
    gap: 8px;
    visibility: hidden;
    pointer-events: none;
    white-space: nowrap;

    .active-filters__chip {
      flex-shrink: 0;
    }
  }

  &__chip,
  &__more {
    :deep(.chip__toggle) {
      font-size: 14px;
    }
  }

  &__chip {
    min-width: 0;
    max-width: 280px;

    :deep(.chip__toggle) {
      min-width: 0;
      padding-right: 8px;
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

  &__remove {
    flex-shrink: 0;
    font-size: 12px;
    color: var(--color-muted, #7a8288);
    transition: color 150ms ease-in-out;
  }

  &__chip:hover &__remove {
    color: var(--color-lifted, #eee);
  }

  &__more {
    flex-shrink: 0;

    :deep(.chip__toggle) {
      color: var(--color-text-dim, #959595);
    }
  }

  &--expanded {
    flex-wrap: wrap;
    .active-filters__chip {
      max-width: 100%;
    }
  }
}
</style>
