<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12 filtered-header">
          <div class="filtered-header-left">
            <Btn
              v-if="hasFilterSlot"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
              size="small"
              @click="toggleFilter"
            >
              <span v-show="isFilterSelected">
                <i class="fas fa-filter" />
              </span>
              <span v-show="!isFilterSelected">
                <i class="far fa-filter" />
              </span>
            </Btn>
          </div>
          <div class="filtered-header-right">
            <slot name="actions" :records="records" />
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <slot name="pagination-top" />
        </div>
      </div>
      <div class="row">
        <transition
          name="slide"
          :appear="true"
          @before-enter="toggleFullscreen"
          @after-leave="toggleFullscreen"
        >
          <div v-if="filterVisible" class="col-12 col-lg-3 col-xxl-2">
            <slot name="filter" />
          </div>
        </transition>
        <div
          :class="{
            'col-lg-9 col-xxl-10': !fullscreen,
          }"
          class="col-12 col-animated"
        >
          <slot
            name="default"
            :records="records"
            :filter-visible="filterVisible"
            :loading="loading"
            :primary-key="primaryKey"
            :empty-box-visible="emptyBoxVisible"
          />

          <slot
            name="empty"
            :filter-visible="filterVisible"
            :hide-empty-box="hideEmptyBox"
            :empty-box-visible="emptyBoxVisible"
          >
            <EmptyBox v-if="!hideEmptyBox" :visible="emptyBoxVisible" />
          </slot>
          <slot name="loader" :loading="loading">
            <Loader v-if="!hideLoading" :loading="loading" :fixed="true" />
          </slot>
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

<script lang="ts" setup>
import Btn from "@/shared/components/BaseBtn/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import EmptyBox from "@/shared/components/EmptyBox/index.vue";
import { useFiltersStore } from "@/shared/stores/filters";
import { useFilters } from "@/shared/composables/useFilters";
import type { I18nPluginOptions } from "@/shared/plugins/I18n";

type Props = {
  name: string;
  records: Record<string, unknown>[];
  loading: boolean;
  primaryKey: string;
  staticFilters?: boolean;
  hideEmptyBox?: boolean;
  hideLoading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  staticFilters: false,
  hideEmptyBox: false,
  hideLoading: false,
});

const fullscreen = ref(false);

const mobile = ref(false);

const filtersStore = useFiltersStore();

const filterVisible = computed(() => {
  return filtersStore.isVisible(props.name);
});

const { isFilterSelected } = useFilters();

const route = useRoute();

const page = computed(() => {
  return Number(route.query.page || 1);
});

const filters = computed(() => {
  return route.query.q || {};
});

const slots = useSlots();

const hasFilterSlot = computed(() => {
  return !!slots.filter;
});

const hasPagintion = computed(() => {
  return !!slots.paginationBottom || !!slots.paginationTop;
});

const i18n = inject<I18nPluginOptions>("i18n");

const filterTooltip = computed(() => {
  if (filterVisible) {
    return i18n?.t("filteredList.actions.hideFilter");
  }

  return i18n?.t("filteredList.actions.showFilter");
});

const emptyBoxVisible = computed(() => {
  return !!(
    !props.loading &&
    !props.records.length &&
    (isFilterSelected.value || (hasPagintion && page.value > 1))
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
  if (isFilterSelected.value) {
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

<script lang="ts">
export default {
  name: "FilteredList",
};
</script>
