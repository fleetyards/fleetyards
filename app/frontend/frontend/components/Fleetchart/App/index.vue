<template>
  <div
    v-if="isShow"
    class="fleetchart-app fade"
    :class="{
      in: isOpen,
      show: isShow,
    }"
  >
    <div
      class="fleetchart-app__offcanvas"
      :class="{
        'fleetchart-app__offcanvas--visible': filterVisible && !mobile,
      }"
    >
      <slot name="filter" />
    </div>
    <div
      class="fleetchart-app__content"
      :class="{
        'fleetchart-app__content--filter-visible': filterVisible && !mobile,
      }"
    >
      <BtnDropdown size="small" class="fleetchart-app-mode">
        <template #label>
          <template v-if="!mobile">
            {{ t("labels.fleetchartApp.mode") }}:
          </template>
          {{ t(`labels.fleetchartApp.modeOptions.${mode}`) }}
        </template>
        <Btn
          v-for="(option, index) in FleetchartModes"
          :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
          size="small"
          variant="dropdown"
          :active="mode === option"
          @click="setMode(option)"
        >
          {{ t(`labels.fleetchartApp.modeOptions.${option}`) }}
        </Btn>
      </BtnDropdown>

      <Btn
        size="large"
        variant="link"
        class="fleetchart-app-close"
        @click="hide"
      >
        <i class="fal fa-times" />
      </Btn>

      <div class="fleetchart-app__filter">
        <Btn
          v-if="hasFilterSlot && !mobile"
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

        <slot v-if="!mobile" name="pagination" />
      </div>

      <template v-if="innerItems.length">
        <FleetchartListPanzoom
          v-if="mode == 'panzoom'"
          :items="innerItems"
          :my-ship="myShip"
          :namespace="namespace"
          :download-name="downloadName"
        />
        <FleetchartList
          v-else
          :items="innerItems"
          :my-ship="myShip"
          :namespace="namespace"
          :download-name="downloadName"
        />
      </template>

      <Loader :loading="loading" :fixed="true" />
    </div>
  </div>
</template>

<script lang="ts" setup>
import FleetchartListPanzoom from "@/frontend/components/Fleetchart/ListPanzoom/index.vue";
import FleetchartList from "@/frontend/components/Fleetchart/List/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import type { Vehicle, Model, VehiclePublic } from "@/services/fyApi";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/shared/composables/useI18n";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useOverlayStore } from "@/shared/stores/overlay";
import { FleetchartModes } from "@/shared/stores/fleetchart";
import { useFiltersStore } from "@/shared/stores/filters";
import { useFilters } from "@/shared/composables/useFilters";

type Props = {
  namespace: string;
  items: (Vehicle | Model | VehiclePublic)[];
  myShip?: boolean;
  downloadName?: string;
  loading?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  myShip: false,
  downloadName: undefined,
  loading: false,
});

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const innerItems = ref<(Vehicle | Model | VehiclePublic)[]>([]);

const isOpen = ref(false);

const isShow = ref(false);

const mobile = useMobile();

const filtersStore = useFiltersStore();

const filterVisible = computed(() => {
  return filtersStore.isVisible(props.namespace);
});

const visible = computed(() => {
  return fleetchartStore.isVisible(props.namespace);
});

const mode = computed(() => {
  return fleetchartStore.fleetchartMode(props.namespace);
});

const { isFilterSelected } = useFilters();

const slots = useSlots();

const hasFilterSlot = computed(() => {
  return !!slots.filter;
});

const filterTooltip = computed(() => {
  if (filterVisible.value) {
    return t("filteredList.actions.hideFilter");
  }

  return t("filteredList.actions.showFilter");
});

watch(
  () => props.items,
  () => {
    updateItems();
  },
);

watch(
  () => visible.value,
  () => {
    if (visible.value) {
      open();
    } else {
      closeFleetchart();
    }
  },
);

const route = useRoute();

onMounted(() => {
  updateItems();

  if (route.query.fleetchart) {
    fleetchartStore.show(props.namespace);
  }

  if (visible.value) {
    open();
  }
});

const toggleFilter = () => {
  filtersStore.toggle(props.namespace);
};

const updateItems = () => {
  innerItems.value = JSON.parse(JSON.stringify(props.items)).sort(
    (a: Vehicle | Model, b: Vehicle | Model) => {
      if (
        (a as Vehicle).model?.metrics?.length &&
        (b as Vehicle).model?.metrics?.length
      ) {
        if (
          (a as Vehicle).model.metrics.length! <
          (b as Vehicle).model.metrics.length!
        ) {
          return -1;
        }

        if (
          (a as Vehicle).model.metrics.length! >
          (b as Vehicle).model.metrics.length!
        ) {
          return 1;
        }

        return 0;
      } else if ((a as Model).metrics?.length && (b as Model).metrics?.length) {
        if ((a as Model).metrics.length! < (b as Model).metrics.length!) {
          return -1;
        }

        if ((a as Model).metrics.length! > (b as Model).metrics.length!) {
          return 1;
        }

        return 0;
      }

      return 0;
    },
  );
};

const emit = defineEmits(["fleetchart-opened", "fleetchart-closed"]);

const overlayStore = useOverlayStore();

const open = () => {
  isShow.value = true;

  overlayStore.show();

  nextTick(() => {
    // make sure the component is present
    setTimeout(() => {
      // make sure initial animations have enough time
      isOpen.value = true;

      emit("fleetchart-opened");
    }, 100);
  });
};

const hide = () => {
  fleetchartStore.hide(props.namespace);
};

const setMode = (mode: FleetchartModes) => {
  fleetchartStore.updateMode({ namespace: props.namespace, mode });
};

const closeFleetchart = () => {
  isOpen.value = false;

  overlayStore.hide();

  nextTick(() => {
    setTimeout(() => {
      isShow.value = false;

      emit("fleetchart-closed");
    }, 300);
  });
};
</script>

<script lang="ts">
export default {
  name: "FleetchartApp",
};
</script>

<style lang="scss" scoped>
@import "index.scss";
</style>
