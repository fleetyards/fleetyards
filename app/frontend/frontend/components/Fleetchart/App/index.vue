<script lang="ts">
export default {
  name: "FleetchartApp",
};
</script>

<script lang="ts" setup>
import FleetchartListPanzoom from "@/frontend/components/Fleetchart/ListPanzoom/index.vue";
import FleetchartList from "@/frontend/components/Fleetchart/List/index.vue";
import FleetchartCanvas from "@/frontend/components/Fleetchart/Canvas/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import AppModalCloseBtn from "@/shared/components/AppModal/CloseBtn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import {
  FeatureFlagName,
  type Model,
  type Vehicle,
  type VehiclePublic,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useMobile } from "@/shared/composables/useMobile";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useFleetchartStore } from "@/shared/stores/fleetchart";
import { useOverlayStore } from "@/shared/stores/overlay";
import { FleetchartLayouts, FleetchartModes } from "@/shared/stores/fleetchart";
import { useFiltersStore } from "@/shared/stores/filters";
import { useFilters } from "@/shared/composables/useFilters";
import { useFleetchartViews } from "@/frontend/composables/useFleetchartViews";
import {
  modelOf,
  type FleetchartEntry,
} from "@/frontend/components/Fleetchart/geometry";
import { BASE_GROUPS } from "@/frontend/components/Fleetchart/options";
import type { FleetchartGroups } from "@/shared/stores/fleetchart";

type Props = {
  namespace: string;
  items: FleetchartEntry[];
  myShip?: boolean;
  downloadName?: string;
  loading?: boolean;
  /** Offers a share control in the chart's own controls. The chart covers the
   *  app header, so a share button teleported there is unreachable while it is
   *  open. */
  shareUrl?: string;
  shareTitle?: string;
  /** Everything a free arrangement can hold, once `arrangeLoaded`. Offers the free
   *  layout when given, as it cannot work on one page of a list. */
  arrangeItems?: FleetchartEntry[];
  arrangeLoaded?: boolean;
  /** Shows a saved arrangement as it is, for someone it was shared with. */
  readOnly?: boolean;
  /** What the ships can be grouped by, which a fleet's own ships widen. */
  groups?: FleetchartGroups[];
};

const props = withDefaults(defineProps<Props>(), {
  myShip: false,
  downloadName: undefined,
  loading: false,
  shareUrl: undefined,
  shareTitle: undefined,
  arrangeItems: undefined,
  arrangeLoaded: false,
  readOnly: false,
  groups: () => BASE_GROUPS,
});

const { t } = useI18n();

const fleetchartStore = useFleetchartStore();

const innerItems = ref<FleetchartEntry[]>([]);

const isOpen = ref(false);

const root = ref<HTMLElement | undefined>();

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

const { isFeatureEnabled } = useFeatures();

// The flag is the owner's: a shared layout was checked when it was fetched, and the
// person opening the link does not need it themselves.
const layoutsEnabled = computed(
  () => props.readOnly || isFeatureEnabled(FeatureFlagName.FLEETCHART_LAYOUTS),
);

const layout = computed(() =>
  fleetchartStore.fleetchartLayout(props.namespace, canArrange.value),
);

// Arranging takes a mouse for now, so a phone is not offered it.
const canArrange = computed(
  () => props.readOnly || (!!props.arrangeItems && !mobile.value),
);

const layoutOptions = computed(() =>
  Object.values(FleetchartLayouts).filter(
    (option) => option !== FleetchartLayouts.FREE || canArrange.value,
  ),
);

const arranging = computed(
  () => layout.value === FleetchartLayouts.FREE && canArrange.value,
);

// The page stays up until the whole fleet has arrived.
const sourceItems = computed(() =>
  arranging.value && props.arrangeLoaded
    ? props.arrangeItems || []
    : props.items,
);

const setLayout = (option: FleetchartLayouts) => {
  fleetchartStore.updateLayout({ namespace: props.namespace, layout: option });
};

const slugs = computed(() =>
  sourceItems.value.map((item) => modelOf(item)?.slug).filter(Boolean),
);

// Fetched only while the chart is open: the lists no longer carry the views, and
// most visitors never open it.
const {
  viewsFor,
  revision,
  loading: viewsLoading,
} = useFleetchartViews(
  () => slugs.value,
  () => visible.value,
);

const extended = computed(() => {
  return fleetchartStore.extendedState(props.namespace);
});

const toggleExtended = () => {
  fleetchartStore.toggleExtended(props.namespace);
};

const extendedTooltip = computed(() => {
  return extended.value
    ? t("actions.fleetchartApp.useRetractedState")
    : t("actions.fleetchartApp.useExtendedState");
});

const hasExtendedItems = computed(() => {
  return sourceItems.value.some((item) => {
    const model = modelOf(item);
    const media = model.media as Model["media"] | undefined;

    return Boolean(
      model.metrics?.extendedLength ||
      media?.extendedHolo ||
      media?.extendedTopView ||
      media?.extendedPortView ||
      media?.extendedAngledView ||
      media?.extendedFrontView,
    );
  });
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

// The views arrive after the chart opens, so the copy has to be rebuilt once they
// land rather than only when the item list changes.
watch(revision, () => {
  updateItems();
});

watch(
  () => visible.value,
  async () => {
    if (visible.value) {
      await open();
    } else {
      await closeFleetchart();
    }
  },
);

const route = useRoute();

onMounted(async () => {
  updateItems();

  if (route.query.fleetchart) {
    fleetchartStore.show(props.namespace);
  }

  if (visible.value) {
    await open();
  }
});

watch([layoutsEnabled, sourceItems], () => {
  updateItems();
});

const toggleFilter = () => {
  filtersStore.toggle(props.namespace);
};

// Merged into this component's own copy of the items, so the item components go
// on reading `model.media` and need no knowledge of where the views came from.
const withViews = (items: FleetchartEntry[]) => {
  items.forEach((item) => {
    const model = modelOf(item);
    const views = model?.slug && viewsFor(model.slug);

    if (views) {
      model.media = { ...model.media, ...views };
    }
  });

  return items;
};

const updateItems = () => {
  // The renderer sorts by the chosen option, and one option is the list's order.
  if (layoutsEnabled.value) {
    innerItems.value = withViews(JSON.parse(JSON.stringify(sourceItems.value)));

    return;
  }

  innerItems.value = withViews(JSON.parse(JSON.stringify(props.items))).sort(
    (a: FleetchartEntry, b: FleetchartEntry) => {
      const lengthA = modelOf(a).metrics?.length;
      const lengthB = modelOf(b).metrics?.length;

      return lengthA && lengthB ? lengthA - lengthB : 0;
    },
  );
};

// The charts behind the flag are typed against full models, but read only what a
// fleet's slim ships carry as well: names, metrics, status and the merged views,
// whose `media` starts out empty.
const legacyItems = computed(
  () => innerItems.value as (Vehicle | Model | VehiclePublic)[],
);

const emit = defineEmits(["fleetchart-opened", "fleetchart-closed"]);

const overlayStore = useOverlayStore();

const comlink = useComlink();

// The chart stacks above the modal layer, which stacks below its own dropdowns, so
// the chart is the one to step back while a modal is open.
const behindModal = ref(false);

const stopListening = [
  comlink.on("open-modal", () => {
    behindModal.value = true;
  }),
  comlink.on("modal-closed", () => {
    behindModal.value = false;
  }),
];

onBeforeUnmount(() => {
  stopListening.forEach((stop) => stop());
});

const open = async () => {
  isShow.value = true;

  overlayStore.show();

  await nextTick(() => {
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

const closeFleetchart = async () => {
  isOpen.value = false;

  overlayStore.hide();

  await nextTick(() => {
    setTimeout(() => {
      isShow.value = false;

      emit("fleetchart-closed");
    }, 300);
  });
};
</script>

<template>
  <div
    v-if="isShow"
    ref="root"
    class="fleetchart-app fade"
    :class="{
      in: isOpen,
      show: isShow,
      'fleetchart-app--behind-modal': behindModal,
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
      <div class="fleetchart-app-controls">
        <slot name="title" />

        <BtnDropdown
          v-if="layoutsEnabled && !readOnly"
          data-test="fleetchart-layout"
        >
          <template #label>
            <template v-if="!mobile">
              {{ t("labels.fleetchartApp.layout") }}:
            </template>
            {{ t(`labels.fleetchartApp.layoutOptions.${layout}`) }}
          </template>
          <Btn
            v-for="option in layoutOptions"
            :key="option"
            :active="layout === option"
            :data-test="`fleetchart-layout-${option}`"
            variant="bare"
            @click="setLayout(option)"
          >
            {{ t(`labels.fleetchartApp.layoutOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <BtnDropdown v-else-if="!readOnly">
          <template #label>
            <template v-if="!mobile">
              {{ t("labels.fleetchartApp.mode") }}:
            </template>
            {{ t(`labels.fleetchartApp.modeOptions.${mode}`) }}
          </template>
          <Btn
            v-for="(option, index) in FleetchartModes"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            :active="mode === option"
            @click="setMode(option)"
            variant="bare"
          >
            {{ t(`labels.fleetchartApp.modeOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <Btn
          v-if="hasExtendedItems && !layoutsEnabled"
          v-tooltip="extendedTooltip"
          :active="extended"
          @click="toggleExtended"
        >
          <i class="fa-duotone fa-arrows-from-line" />
        </Btn>

        <ShareBtn
          v-if="shareUrl"
          :url="shareUrl"
          :title="shareTitle || ''"
          :container="root"
          no-label
        />

        <slot name="controls" />
      </div>

      <AppModalCloseBtn
        class="fleetchart-app-close"
        data-test="fleetchart-app-close"
        @click="hide"
      />

      <div class="fleetchart-app__filter">
        <Btn
          v-if="hasFilterSlot && !mobile"
          v-tooltip="filterTooltip"
          :active="filterVisible"
          :aria-label="filterTooltip"
          @click="toggleFilter"
        >
          <span v-show="isFilterSelected">
            <i class="fa-solid fa-filter" />
          </span>
          <span v-show="!isFilterSelected">
            <i class="fa-regular fa-filter" />
          </span>
        </Btn>

        <slot v-if="!mobile && !arranging" name="pagination" />
      </div>

      <!-- A free arrangement can start empty, as ships can be added to it. -->
      <template v-if="innerItems.length || (layoutsEnabled && arranging)">
        <FleetchartCanvas
          v-if="layoutsEnabled"
          :items="innerItems"
          :namespace="namespace"
          :download-name="downloadName"
          :can-arrange="canArrange"
          :read-only="readOnly"
          :arrange-ready="!arranging || arrangeLoaded"
          :groups="groups"
        />
        <FleetchartListPanzoom
          v-else-if="mode == 'panzoom'"
          :items="legacyItems"
          :my-ship="myShip"
          :namespace="namespace"
          :download-name="downloadName"
        />
        <FleetchartList
          v-else
          :items="legacyItems"
          :my-ship="myShip"
          :namespace="namespace"
          :download-name="downloadName"
        />
      </template>

      <Loader :loading="loading || viewsLoading" :fixed="true" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
