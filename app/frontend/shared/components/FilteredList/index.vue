<script lang="ts">
export default {
  name: "FilteredList",
};
</script>

<script lang="ts" setup generic="T">
import Btn from "@/shared/components/base/Btn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import EmptyBox from "@/shared/components/EmptyBox/index.vue";
import { useFiltersStore } from "@/shared/stores/filters";
import { type AsyncStatus } from "@/shared/components/AsyncData.types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  name: string;
  records: T[];
  asyncStatus: AsyncStatus;
  staticFilters?: boolean;
  hideEmptyBox?: boolean;
  hideLoading?: boolean;
  isFilterSelected?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  staticFilters: false,
  hideEmptyBox: false,
  hideLoading: false,
  isFilterSelected: false,
});

const loading = computed(() => {
  return (
    (props.asyncStatus.isFetching.value &&
      !props.asyncStatus.isRefetching.value) ||
    props.asyncStatus.isLoading.value
  );
});

const fullscreen = ref(false);

const mobile = ref(false);

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

const { t } = useI18n();

const filterTooltip = computed(() => {
  if (filterVisible) {
    return t("filteredList.actions.hideFilter");
  }

  return t("filteredList.actions.showFilter");
});

const emptyBoxVisible = computed(() => {
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

onMounted(() => {
  if (mobile.value) {
    filtersStore.hide(props.name);
  } else if (props.staticFilters) {
    filtersStore.show(props.name);
  }

  toggleFullscreen();
  saveFilters();

  window.addEventListener("resize", checkMobile);
  checkMobile();
});

onUnmounted(() => {
  window.removeEventListener("resize", checkMobile);
});

const checkMobile = () => {
  mobile.value = document.documentElement.clientWidth < 992;
};

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
  filtersStore.toggle(props.name);
};
</script>

<template>
  <div class="row filtered-list">
    <div class="col-12">
      <div class="row">
        <div class="col-12 filtered-list__header">
          <div class="filtered-list__header-left">
            <Btn
              v-if="hasFilterSlot"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
              :size="BtnSizesEnum.SMALL"
              @click="toggleFilter"
            >
              <i v-if="isFilterSelected" class="fas fa-filter" />
              <i v-else class="far fa-filter" />
            </Btn>
            <slot name="actions-left" :records="records" />
          </div>
          <div class="filtered-list__header-right">
            <slot name="actions-right" :records="records" />
            <slot name="pagination-top" />
          </div>
        </div>
      </div>
      <div class="row">
        <transition
          name="slide"
          :appear="true"
          @before-enter="toggleFullscreen"
          @after-leave="toggleFullscreen"
        >
          <div v-show="filterVisible" class="col-12 col-lg-3 col-xxl-2">
            <slot name="filter" />
          </div>
        </transition>
        <div
          :class="{
            'col-lg-9 col-xxl-10': !fullscreen,
          }"
          class="col-12 col-animated"
        >
          <slot v-if="!hideLoading && loading" name="loader" :loading="loading">
            <Loader :loading="loading" :fixed="true" />
          </slot>

          <slot
            v-else-if="!hideEmptyBox && emptyBoxVisible"
            name="empty"
            :filter-visible="filterVisible"
            :hide-empty-box="hideEmptyBox"
            :empty-box-visible="emptyBoxVisible"
          >
            <transition name="fade">
              <EmptyBox />
            </transition>
          </slot>

          <slot
            v-else
            name="default"
            :records="records"
            :filter-visible="filterVisible"
            :loading="loading"
            :empty-box-visible="emptyBoxVisible"
          />
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
