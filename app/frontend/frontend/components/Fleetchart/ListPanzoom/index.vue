<template>
  <div class="row fleetchart-list-panzoom">
    <div class="col-12 fleetchart-wrapper">
      <div class="fleetchart-controls">
        <Starship42Btn v-if="!mobile" size="small" :items="items" />

        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ t("labels.fleetchartApp.screenHeight") }}:
            </template>
            {{
              t(
                `labels.fleetchartApp.screenHeightOptions.${selectedScreenHeight}`,
              )
            }}
          </template>
          <Btn
            v-for="(option, index) in FleetchartScreenHeights"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="selectedScreenHeight === option"
            @click="setScreenHeight(option)"
          >
            {{ t(`labels.fleetchartApp.screenHeightOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <BtnDropdown size="small">
          <template #label>
            <template v-if="!mobile">
              {{ t("labels.fleetchartApp.viewpoint") }}:
            </template>
            {{ t(`labels.fleetchartApp.viewpointOptions.${viewpoint}`) }}
          </template>
          <Btn
            v-for="(option, index) in FleetchartViewpoints"
            :key="`fleetchart-screen-height-drowndown-${index}-${option}`"
            size="small"
            variant="link"
            :active="viewpoint === option"
            @click="setViewpoint(option)"
          >
            {{ t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
          </Btn>
        </BtnDropdown>

        <Btn size="small" :active="gridEnabled" @click="toggleGrid">
          <i class="fad fa-th" />
        </Btn>

        <Btn size="small" :active="coloredEnabled" @click="toggleColored">
          <i class="fad fa-palette" />
        </Btn>

        <BtnDropdown size="small">
          <template v-if="downloadName">
            <DownloadScreenshotBtn
              element="#fleetchart"
              :filename="downloadName"
              size="small"
              variant="dropdown"
            />

            <hr />
          </template>

          <Starship42Btn
            v-if="mobile"
            :items="items"
            size="small"
            variant="dropdown"
            :with-icon="true"
          />

          <Btn size="small" variant="dropdown" @click="toggleLabels">
            <i class="fad fa-tags" />
            <span v-if="showLabels">
              {{ t("actions.hideLabels") }}
            </span>
            <span v-else>
              {{ t("actions.showLabels") }}
            </span>
          </Btn>

          <FleetChartStatusBtn variant="dropdown" size="small" />

          <Btn size="small" variant="dropdown" @click="markForReset">
            <i class="fad fa-undo" />
            <span>{{ t("actions.resetZoom") }}</span>
          </Btn>
        </BtnDropdown>
      </div>
      <div
        class="fleetchart-grid-label"
        :class="{
          'fleetchart-grid-enabled': gridEnabled,
        }"
      >
        {{ t("labels.fleetchartApp.gridSize", { size: gridSizeLabel }) }}
      </div>
      <div class="fleetchart-scroll-wrapper">
        <div id="fleetchart" ref="fleetchart" class="fleetchart">
          <transition-group
            v-for="(colItems, index) in fleetchartColumns"
            :key="`fleetchart-col-${index}`"
            name="fade-list"
            :appear="true"
            class="fleetchart-column"
          >
            <FleetchartItem
              v-for="item in colItems"
              :key="item.id"
              :item="item"
              :viewpoint="viewpoint"
              :show-label="showLabels"
              :show-status="showStatus"
              :size-multiplicator="sizeMultiplicator"
              :scale="scale"
              :colored="coloredEnabled"
            />
          </transition-group>

          <transition-group
            name="fade-list"
            tag="div"
            :appear="true"
            class="fleetchart-download-image"
          >
            <div
              key="made-by-the-community"
              class="fleetchart-item fade-list-item"
            >
              <CommunityLogo />
            </div>
          </transition-group>
        </div>
        <canvas
          ref="fleetchartGrid"
          class="fleetchart-grid"
          :class="{
            'fleetchart-grid-enabled': gridEnabled,
          }"
          :width="screenWidth"
          :height="screenHeight"
        />
      </div>
    </div>
  </div>
</template>

<script lang="ts" setup>
import panzoom from "panzoom";
import type { PanZoom } from "panzoom";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import DownloadScreenshotBtn from "@/frontend/components/DownloadScreenshotBtn/index.vue";
import FleetChartStatusBtn from "@/frontend/components/FleetChartStatusBtn/index.vue";
import debounce from "lodash.debounce";
import Starship42Btn from "@/frontend/components/Starship42Btn/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import FleetchartItem from "./Item/index.vue";
import { useMobile } from "@/shared/composables/useMobile";
import { useI18n } from "@/frontend/composables/useI18n";
import type {
  Vehicle,
  Model,
  VehiclePublic,
  ModelPaint,
  ModelModulePackage,
} from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import {
  FleetchartScreenHeights,
  FleetchartViewpoints,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

const { t } = useI18n();

type Props = {
  namespace: string;
  items?: (Vehicle | Model | VehiclePublic)[];
  myShip?: boolean;
  downloadName?: string;
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  myShip: false,
  downloadName: undefined,
});

const showStatus = ref(false);

const zoomSpeed = 0.5;

const maxZoom = 20;

const minZoom = 0.2;

const pinchSpeed = 3;

const margin = 80;

const innerMargin = 20;

const marginBottom = 40;

const gridEnabled = ref(false);

const screenWidth = ref<number>();

const screenHeight = ref<number>();

const gridSize = 80.0;

const panzoomInstance = ref<PanZoom>();

const fleetchartColumns = ref<
  Record<number, (Vehicle | Model | VehiclePublic)[]>
>({});

const markedForReset = ref(false);

const sizeMultiplicator = ref(4);

const mobile = useMobile();

const gridSizeLabel = computed(() => {
  return (
    gridSize /
    (initialZoomData.value?.scale || 1) /
    sizeMultiplicator.value
  )
    .toFixed(2)
    .replace(".00", "");
});

const fleetchartStore = useFleetchartStore();

const viewpoint = computed(() => {
  return fleetchartStore.fleetchartViewpoint(props.namespace);
});

const showLabels = computed(() => {
  return fleetchartStore.showLabels(props.namespace);
});

const coloredEnabled = computed(() => {
  return fleetchartStore.colored(props.namespace);
});

const selectedScreenHeight = computed(() => {
  return fleetchartStore.fleetchartScreenHeight(props.namespace);
});

const screenHeightFactor = computed(() => {
  return {
    "1x": 1,
    "1_5x": 1.5,
    "2x": 2,
    "3x": 3,
    "4x": 4,
  }[selectedScreenHeight.value];
});

const maxColHeight = computed(() => {
  if (!screenHeight.value) {
    return 0;
  }

  return screenHeight.value * screenHeightFactor.value - margin - marginBottom;
});

const initialZoomData = computed(() => {
  return fleetchartStore.fleetchartZoomData(props.namespace);
});

const scale = computed(() => {
  return initialZoomData.value?.scale || 1;
});

watch(
  () => props.items,
  () => {
    setupColumns();
  },
);

const route = useRoute();

const comlink = useComlink();

onMounted(() => {
  showStatus.value = !!route.query?.showStatus;

  comlink.on("fleetchart-toggle-status", toggleStatus);

  updateScreenSize();

  setupColumns();

  setupZoom();

  window.addEventListener("resize", updateScreenSize);
  window.addEventListener("deviceorientation", updateScreenSize);
});

onUnmounted(() => {
  comlink.off("fleetchart-toggle-status");

  panzoomInstance.value?.dispose();

  panzoomInstance.value = undefined;

  window.removeEventListener("resize", updateScreenSize);
  window.removeEventListener("deviceorientation", updateScreenSize);
});

const updateZoomData = () => {
  const transform = panzoomInstance.value?.getTransform();

  if (!transform) {
    return;
  }

  fleetchartStore.updateZoomData({
    namespace: props.namespace,
    zoomData: transform,
  });
};

const debouncedUpdateZoomData = debounce(updateZoomData, 300);

const fleetchart = ref<HTMLElement>();

const setupZoom = async () => {
  if (!fleetchart.value) {
    return;
  }

  panzoomInstance.value = panzoom(fleetchart.value, {
    maxZoom: maxZoom,
    minZoom: minZoom,
    zoomSpeed: zoomSpeed,
    pinchSpeed: pinchSpeed,
  });

  if (initialZoomData.value?.scale) {
    panzoomInstance.value.zoomAbs(0, 0, initialZoomData.value.scale);

    // hack to apply latest location after zooming.
    setTimeout(() => {
      panzoomInstance.value?.moveTo(
        initialZoomData.value.x,
        initialZoomData.value.y,
      );
    }, 300);
  }

  panzoomInstance.value.on("zoom", (_event) => {
    debouncedUpdateZoomData();
  });

  panzoomInstance.value.on("pan", (_event) => {
    debouncedUpdateZoomData();
  });

  panzoomInstance.value.on("transform", (_event) => {
    debouncedCheckReset();
  });
};

const checkReset = () => {
  if (markedForReset) {
    markedForReset.value = false;

    resetZoom();
  }
};

const debouncedCheckReset = debounce(checkReset, 300);

const updateScreenSize = () => {
  screenWidth.value = window.innerWidth;
  screenHeight.value = window.innerHeight;

  drawGridLines();
};

const setupColumns = () => {
  fleetchartColumns.value = {};
  let index = 0;
  let colHeight = 0;

  props.items.forEach((item) => {
    const model = (item as Vehicle).model || item;
    const length =
      (model.metrics.fleetchartLength || 0) * sizeMultiplicator.value;

    const height = (length * imageMaxHeight(item)) / imageMaxWidth(item);

    if (Number.isNaN(height)) {
      return;
    }

    colHeight += height;

    if (colHeight > maxColHeight.value) {
      colHeight = height;
      index += 1;
    }

    colHeight += innerMargin;

    fleetchartColumns.value[index] = [
      ...(fleetchartColumns.value[index] || []),
      item,
    ];
  });
};

const toggleGrid = () => {
  gridEnabled.value = !gridEnabled.value;

  drawGridLines();
};

const toggleColored = () => {
  fleetchartStore.toggleColored(props.namespace);
};

const setViewpoint = (viewpoint: FleetchartViewpoints) => {
  fleetchartStore.updateViewpoint({
    namespace: props.namespace,
    viewpoint,
  });
};

const setScreenHeight = (screenHeight: FleetchartScreenHeights) => {
  fleetchartStore.updateScreenHeight({
    namespace: props.namespace,
    screenHeight,
  });

  setupColumns();
};

const toggleStatus = () => {
  showStatus.value = !showStatus.value;
};

const toggleLabels = () => {
  fleetchartStore.toggleLabels(props.namespace);
};

const fleetchartGrid = ref<HTMLCanvasElement>();

const drawGridLines = async () => {
  if (!gridEnabled.value) {
    return;
  }

  await nextTick();

  const canvas = fleetchartGrid.value;

  if (!canvas) {
    return;
  }

  if (canvas.getContext) {
    const ctx = canvas.getContext("2d");

    if (!ctx) {
      return;
    }

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const drawVerticalLine = (
      left: number,
      top: number,
      height: number,
      color: string | CanvasGradient | CanvasPattern,
    ) => {
      ctx.fillStyle = color;
      ctx.fillRect(left, top, 1, height);
    };

    const drawHorizontalLine = (
      left: number,
      top: number,
      width: number,
      color: string | CanvasGradient | CanvasPattern,
    ) => {
      ctx.fillStyle = color;
      ctx.fillRect(left, top, width, 1);
    };

    const lineColor = "rgba(255, 255, 255, 0.5)";

    for (let i = 0; i < canvas.width; i += gridSize) {
      drawVerticalLine(i, 0, canvas.height, lineColor);
    }

    for (let i = 0; i < canvas.height; i += gridSize) {
      drawHorizontalLine(0, i, canvas.width, lineColor);
    }
  }
};

const resetZoom = () => {
  panzoomInstance.value?.zoomAbs(0, 0, 1);
  panzoomInstance.value?.moveTo(0, 0);
};

const markForReset = () => {
  markedForReset.value = true;

  setTimeout(() => {
    checkReset();
  }, 300);
};

const extractMaxWidthFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  return Math.max(
    model.media.topView?.width || 0,
    model.media.sideView?.width || 0,
    model.media.angledView?.width || 0,
  );
};

const extractMaxHeightFromModel = (
  model: Model | ModelPaint | ModelModulePackage,
) => {
  return Math.max(
    model.media.topView?.height || 0,
    model.media.sideView?.height || 0,
    model.media.angledView?.height || 0,
  );
};

const imageMaxHeight = (item: Vehicle | Model | VehiclePublic) => {
  const model = (item as Vehicle).model || item;
  const vehicle = item as Vehicle;

  if (
    vehicle.modulePackage &&
    (vehicle.modulePackage.media.topView ||
      vehicle.modulePackage.media.sideView ||
      vehicle.modulePackage.media.angledView)
  ) {
    const height = extractMaxHeightFromModel(vehicle.modulePackage);
    if (height) {
      return height;
    }
  }

  if (
    vehicle.paint &&
    (vehicle.paint.media.topView ||
      vehicle.paint.media.sideView ||
      vehicle.paint.media.angledView)
  ) {
    const height = extractMaxHeightFromModel(vehicle.paint);
    if (height) {
      return height;
    }
  }

  return extractMaxHeightFromModel(model);
};

const imageMaxWidth = (item: Vehicle | Model | VehiclePublic) => {
  const model = (item as Vehicle).model || item;
  const vehicle = item as Vehicle;

  if (
    vehicle.modulePackage &&
    (vehicle.modulePackage.media.topView ||
      vehicle.modulePackage.media.sideView ||
      vehicle.modulePackage.media.angledView)
  ) {
    const width = extractMaxWidthFromModel(vehicle.modulePackage);
    if (width) {
      return width;
    }
  }

  if (
    vehicle.paint &&
    (vehicle.paint.media.topView ||
      vehicle.paint.media.sideView ||
      vehicle.paint.media.angledView)
  ) {
    const width = extractMaxWidthFromModel(vehicle.paint);
    if (width) {
      return width;
    }
  }

  return extractMaxWidthFromModel(model);
};
</script>

<script lang="ts">
export default {
  name: "FleetchartListPanzoom",
};
</script>
