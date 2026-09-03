<script lang="ts">
export default {
  name: "FilteredList",
};
</script>

<script lang="ts" setup generic="T">
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import ServerError from "@/shared/components/ServerError/index.vue";
import Forbidden from "@/shared/components/Forbidden/index.vue";
import { useFiltersStore } from "@/shared/stores/filters";
import { usePaginationStore } from "@/shared/stores/pagination";
import { provideListGeometry } from "@/shared/composables/useListGeometry";
import { useMinimumDuration } from "@/shared/composables/useMinimumDuration";
import { useListGeometryStore } from "@/shared/stores/listGeometry";
import {
  type AsyncStatus,
  ErrorTypesEnum,
} from "@/shared/components/AsyncData.types";
import { errorTypeFrom } from "@/shared/utils/ErrorTypes";

import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  name: string;
  records: T[];
  asyncStatus: AsyncStatus;
  staticFilters?: boolean;
  hideEmpty?: boolean;
  hideLoading?: boolean;
  isFilterSelected?: boolean;
  // Render the list itself while its first page loads rather than a spinner in
  // an empty box. It is handed no records, which is what a table needs to draw
  // its header and a page of placeholder rows; a list of cards renders nothing
  // from an empty set and brings a `skeleton` slot instead.
  placeholders?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  staticFilters: false,
  hideEmpty: false,
  hideLoading: false,
  isFilterSelected: false,
  placeholders: false,
});

const fetching = computed(() => {
  return (
    (props.asyncStatus.isFetching.value &&
      !props.asyncStatus.isRefetching.value) ||
    props.asyncStatus.isLoading.value
  );
});

// Held on the way down: a list that answers as fast as a cached page does puts
// its placeholders up and takes them away again inside a frame or two, and a
// box that fills with grey bars and empties reads as a glitch rather than as a
// load. See useMinimumDuration.
const loading = useMinimumDuration(() => fetching.value);

const refetching = computed(() => {
  return props.asyncStatus.isRefetching.value;
});

const fullscreen = ref(false);

const mobile = useMobile();

const comlink = useComlink();

const filtersStore = useFiltersStore();

const filterVisible = computed(() => {
  return filtersStore.isVisible(props.name);
});

const route = useRoute();

const filters = computed(() => {
  return route.query.q || {};
});

const slots = useSlots();

const hasFilterSlot = computed(() => {
  return !!slots.filter;
});

// A list that brings no filter, no actions and no pagination has an empty
// toolbar, and an empty toolbar is still 20px of margin between the page and
// the records.
const hasActions = computed(
  () =>
    hasFilterSlot.value ||
    !!slots["actions-left"] ||
    !!slots["actions-right"] ||
    !!slots["pagination-top"],
);

// Both blocks only exist where their slot does: an empty one still claims the
// toolbar's column gap, which on a phone is the difference between the actions
// and the paginator sharing a row and the paginator wrapping below them.
const hasActionsRight = computed(() => !!slots["actions-right"]);

const hasPaginationTop = computed(() => !!slots["pagination-top"]);

// A toolbar holding nothing but the paginator has no left-hand side to align
// away from, so the control reads as centred rather than pushed to one edge.
const paginationOnly = computed(
  () =>
    !!slots["pagination-top"] &&
    !hasFilterSlot.value &&
    !slots["actions-left"] &&
    !slots["actions-right"],
);

const paginationStore = usePaginationStore();

const geometryStore = useListGeometryStore();

// Once the answer is in, whatever it held - including nothing. `isPending` is
// what separates "the list is empty" from "the list has not answered yet", and
// only the first of those is worth remembering.
watch(
  [() => props.records.length, () => props.asyncStatus.isPending.value],
  ([count, pending]) => {
    if (!pending) {
      geometryStore.recordCount(props.name, count);
    }
  },
  { immediate: true },
);

// Per-page lives in the store keyed by route, the same place usePagination
// reads it - so a list opts into placeholders without also having to pass its
// pagination down. It is unset until somebody picks a size, and the first step
// of the dropdown is what the API falls back to.
//
// Capped by the most this list has ever held, because a page size is an upper
// bound and not a promise: a ship's videos are two, and ten placeholders the
// height of a video embed is a screen and a half of nothing. On a list that
// fills its pages the two agree.
const skeletonCount = computed(() => {
  const perPage =
    Number(paginationStore.findByKey((route.name as string) || "")) ||
    undefined;

  const seen = geometryStore.countByKey(props.name);

  // Nobody has picked a size, so the API's default is in force - and the count
  // of the last answer is the only reading of what that is.
  if (perPage === undefined) {
    return seen ?? 10;
  }

  return seen === undefined ? perPage : Math.min(perPage, seen);
});

// Offered to whatever renders inside: the count above, and how tall one record
// was the last time this list drew any. The list reports its own measurement
// back, so neither a table nor a grid carries a height written by hand.
//
// The spinner goes with it, because a list told to hide this one - a table view
// that would rather use its own - has to know that it is on its own.
provideListGeometry(
  () => props.name,
  skeletonCount,
  computed(() => !props.hideLoading && loading.value),
);

const { t } = useI18n();

const filterTooltip = computed(() => {
  if (filterVisible.value) {
    return t("filteredList.actions.hideFilter");
  }

  return t("filteredList.actions.showFilter");
});

const error = computed(() => {
  return props.asyncStatus.isError.value;
});

// A list behind a flag that is not on yet, or a record belonging to somebody
// else, comes back 403 — which is an answer, not an outage.
const forbidden = computed(
  () =>
    errorTypeFrom(props.asyncStatus.error?.value) === ErrorTypesEnum.FORBIDDEN,
);

const emptyVisible = computed(() => {
  return !!(
    props.asyncStatus?.fetchStatus.value === "idle" && !props.records.length
  );
});

watch(
  () => filters.value,
  () => {
    saveFilters();
  },
  { deep: true },
);

const onOffCanvasClosed = ref();

onMounted(() => {
  if (mobile.value) {
    filtersStore.hide(props.name);
  } else if (props.staticFilters) {
    filtersStore.show(props.name);
  }

  toggleFullscreen();
  saveFilters();

  onOffCanvasClosed.value = comlink.on("off-canvas-closed", () => {
    filtersStore.hide(props.name);
  });
});

onUnmounted(() => {
  onOffCanvasClosed.value?.();
});

// Close OffCanvas when resizing from mobile to desktop
watch(mobile, (isMobile, wasMobile) => {
  if (wasMobile && !isMobile && filterVisible.value) {
    comlink.emit("close-off-canvas");
  }
});

const saveFilters = () => {
  if (props.isFilterSelected) {
    filtersStore.setFilter(props.name, {
      ...filters.value,
    });

    return;
  }

  filtersStore.removeFilter(props.name);
};

const toggleFullscreen = () => {
  fullscreen.value = !filterVisible.value;
};

const toggleFilter = () => {
  if (mobile.value) {
    if (filterVisible.value) {
      comlink.emit("close-off-canvas");
    } else {
      filtersStore.show(props.name);
      comlink.emit("open-off-canvas", {
        title: t("filteredList.actions.showFilter"),
        side: "left",
      });
    }
  } else {
    filtersStore.toggle(props.name);
  }
};
</script>

<template>
  <div
    class="row filtered-list"
    :class="{ 'filtered-list--pagination-only': paginationOnly }"
  >
    <div class="col-12">
      <div class="row">
        <div class="col-12 filtered-list__header">
          <slot name="header" />
        </div>
        <div v-if="hasActions" class="col-12 filtered-list__actions">
          <div class="filtered-list__actions-left">
            <Btn
              v-if="hasFilterSlot"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
              @click="toggleFilter"
            >
              <i v-if="isFilterSelected" class="fa-solid fa-filter" />
              <i v-else class="fa-regular fa-filter" />
            </Btn>
            <slot name="actions-left" :records="records" />
          </div>
          <div v-if="hasActionsRight" class="filtered-list__actions-right">
            <slot name="actions-right" :records="records" />
          </div>
          <!-- A sibling of the two action blocks, not a child of the right one:
               a phone toolbar that does not fit should drop the paginator to a
               row of its own and keep the buttons up with the filter, and a flex
               line breaks on a child's unwrapped width - so the paginator has to
               be that child. -->
          <div v-if="hasPaginationTop" class="filtered-list__pagination-top">
            <slot name="pagination-top" />
          </div>
        </div>
      </div>
      <div class="row">
        <Teleport to="#off-canvas-content" :disabled="!mobile">
          <transition
            v-if="!mobile"
            name="slide"
            :appear="true"
            @before-enter="toggleFullscreen"
            @after-leave="toggleFullscreen"
          >
            <div v-show="filterVisible" class="col-12 col-md-3 col-xxl-2">
              <slot name="filter" />
            </div>
          </transition>
          <div v-else v-show="filterVisible">
            <slot name="filter" />
          </div>
        </Teleport>
        <div
          :class="{
            'col-md-9 col-xxl-10': !fullscreen,
          }"
          class="col-12 col-animated"
        >
          <slot v-if="error" name="error">
            <transition name="fade">
              <Forbidden v-if="forbidden" />
              <ServerError v-else />
            </transition>
          </slot>

          <div
            v-else-if="!hideLoading && loading"
            class="filtered-list__loader"
          >
            <!-- `slots` is read at render time rather than through a computed:
                 a call site is free to gate its placeholders behind a
                 condition, and `slots` is not reactive, so a computed would
                 answer from the render before that condition changed. -->
            <template v-if="slots.skeleton">
              <Loader :loading="loading" fixed />

              <slot
                name="skeleton"
                :count="skeletonCount"
                :filter-visible="filterVisible"
              />
            </template>

            <!-- The list draws its own waiting state: a table hands its header
                 and a page of placeholder rows straight out of an empty record
                 set, which is closer to what arrives than anything written
                 beside it could be. -->
            <template v-else-if="props.placeholders">
              <Loader :loading="loading" fixed />

              <slot
                name="default"
                :records="props.records"
                :filter-visible="filterVisible"
                :loading="loading"
                :refetching="refetching"
                :empty-visible="false"
              />
            </template>

            <slot v-else name="loader" :loading="loading">
              <Loader :loading="loading" relative />
            </slot>
          </div>

          <slot
            v-else-if="!hideEmpty && emptyVisible"
            name="empty"
            :filter-visible="filterVisible"
            :hide-empty="hideEmpty"
            :empty-visible="emptyVisible"
          >
            <transition name="fade">
              <Empty variant="box" />
            </transition>
          </slot>

          <template v-else>
            <Loader :loading="refetching" fixed />

            <slot
              name="default"
              :records="records"
              :filter-visible="filterVisible"
              :loading="loading"
              :refetching="refetching"
              :empty-visible="emptyVisible"
            />
          </template>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <slot name="pagination-bottom" />
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
