<template>
  <div class="row">
    <div class="col-12">
      <div class="row">
        <div class="col-12">
          <slot name="headline" :records="collection && collection.records" />
        </div>
      </div>
      <div class="row">
        <div class="col-12 filtered-header">
          <div class="filtered-header-left">
            <Btn
              v-if="hasFilterSlot"
              v-tooltip="filterTooltip"
              :active="filterVisible"
              :aria-label="filterTooltip"
              size="small"
              @click.native="toggleFilter"
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
            <slot name="actions" :records="collection && collection.records" />
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
            :records="collection && collection.records"
            :filter-visible="filterVisible"
            :loading="loading"
            :primary-key="collection.primaryKey"
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
          <slot name="pagination-bottom">
            <Paginator
              v-if="paginated && collection.records.length"
              :collection="collection"
              :page="page"
            />
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import {
  ref,
  computed,
  watch,
  onMounted,
  onBeforeUnmount,
  nextTick,
  useSlots,
} from "vue";
import type {
  FleetYardsRouteQuery,
  FleetYardsRouteParams,
} from "@/frontend/utils/Sorting";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Paginator from "@/frontend/core/components/Paginator/index.vue";
import Loader from "@/frontend/core/components/Loader/index.vue";
import EmptyBox from "@/frontend/core/components/EmptyBox/index.vue";
import { scrollToAnchor } from "@/frontend/utils/scrolling";
import { isFilterSelected as filterSelected } from "@/frontend/utils/Filters";
import type BaseCollection from "@/frontend/api/collections/Base";
import { useAppStore } from "@/frontend/stores/App";
import { useI18n } from "@/frontend/composables/useI18n";
import { useComlink } from "@/frontend/composables/useComlink";

interface Props {
  collection: BaseCollection<TRecordTypes, any>;
  name: string;
  recordListClass?: string;
  params?: FleetYardsRouteParams;
  collectionMethod?: string;
  routeQuery?: FleetYardsRouteQuery;
  hash?: string;
  paginated?: boolean;
  alwaysFilterVisible?: boolean;
  hideEmptyBox?: boolean;
  hideLoading?: boolean;
  routeFilterName?: string;
}

const props = withDefaults(defineProps<Props>(), {
  recordListClass: undefined,
  params: undefined,
  collectionMethod: "findAll",
  routeQuery: undefined,
  hash: undefined,
  paginated: false,
  alwaysFilterVisible: false,
  hideEmptyBox: false,
  hideLoading: false,
  routeFilterName: "q",
});

const collectionMethodDefault = "findAll";
const routeFilterNameDefault = "q";

const loading = ref(true);

const fullscreen = ref(false);

const filters = computed(() => {
  if (!props.routeQuery) {
    return {};
  }

  return props.routeQuery[props.routeFilterName || routeFilterNameDefault];
});

const search = computed(() => props.routeQuery?.search);

const slots = useSlots();

const hasFilterSlot = computed(() => !!slots.filter);

const page = computed(() => {
  if (!props.routeQuery?.page) {
    return 1;
  }

  return parseInt(props.routeQuery.page, 10);
});

const appStore = useAppStore();

const filterVisible = computed(
  () => !!appStore.filtersVisible[props.name] && hasFilterSlot.value
);

const { t } = useI18n();

const filterTooltip = computed(() => {
  if (filterVisible.value) {
    return t("actions.hideFilter");
  }

  return t("actions.showFilter");
});

const isFilterSelected = computed(() => filterSelected(filters.value));

const emptyBoxVisible = computed(
  () =>
    !!(
      !loading.value &&
      !props.collection.records.length &&
      (isFilterSelected.value || (props.paginated && page.value))
    )
);

watch(
  () => filters.value,
  () => {
    saveFilters();
  },
  { deep: true }
);

watch(
  () => props.routeQuery,
  () => {
    fetch();
  }
);

if (props.collection.records.length) {
  props.collection.resetRecords();
}

const comlink = useComlink();

const saveFilters = () => {
  if (isFilterSelected.value) {
    appStore.saveFilters(props.name, { ...filters.value });

    return;
  }

  appStore.saveFilters(props.name, null);
};

const toggleFullscreen = () => {
  fullscreen.value = !filterVisible.value;
};

onMounted(() => {
  fetch();

  if (appStore.mobile) {
    appStore.filtersVisible[props.name] = false;
  } else if (props.alwaysFilterVisible) {
    appStore.filtersVisible[props.name] = true;
  }

  toggleFullscreen();
  saveFilters();

  comlink.$on("filteredListUpdate", fetch);
});

onBeforeUnmount(() => {
  comlink.$off("filteredListUpdate");
});

const toggleFilter = () => {
  appStore.toggleFilterVisible(props.name);
};

const fetch = async () => {
  loading.value = true;

  let params: TCollectionParams<any> = {
    search: search.value,
    filters: filters.value,
  };

  if (props.paginated) {
    params = {
      ...params,
      ...props.params,
      filters: {
        ...params.filters,
        ...props.params?.filters,
      },
      page: page.value,
    };
  }

  if (!props.collection[props.collectionMethod || collectionMethodDefault]) {
    throw Error(`Method "${props.collectionMethod}" not found on Collection`);
  }

  await props.collection[props.collectionMethod || collectionMethodDefault](
    params
  );

  nextTick(() => {
    scrollToAnchor(props.hash);
  });

  setTimeout(() => {
    loading.value = false;
  }, 300);
};
</script>

<script lang="ts">
export default {
  name: "FilteredList",
};
</script>
