<script lang="ts">
export default {
  name: "FleetchartCanvas",
};
</script>

<script lang="ts" setup>
import panzoom from "panzoom";
import type { PanZoom, Transform } from "panzoom";
import debounce from "lodash.debounce";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import DownloadScreenshotBtn from "@/frontend/components/DownloadScreenshotBtn/index.vue";
import FleetChartStatusBtn from "@/frontend/components/FleetChartStatusBtn/index.vue";
import FleetchartCanvasItem from "./Item/index.vue";
import {
  PIXELS_PER_METRE,
  modelOf,
  shipGeometry,
  shipLabelOf,
  type FleetchartEntry,
} from "@/frontend/components/Fleetchart/geometry";
import {
  arrangeClassic,
  arrangeColumns,
  autoScreenHeightFactor,
  boundsOf,
  gridCellFor,
  withRowWidth,
} from "@/frontend/components/Fleetchart/layouts";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import {
  FleetchartLayouts,
  FleetchartScreenHeights,
  FleetchartViewpoints,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

type Props = {
  namespace: string;
  items?: FleetchartEntry[];
  downloadName?: string;
};

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  downloadName: undefined,
});

const SCENE_PADDING = 40;
const SCREEN_MARGIN = 120;
const MIN_ZOOM = 0.2;
const MAX_ZOOM = 20;
const LABEL_FONT_SCALE = 1.2;
const LABEL_LINE_HEIGHT = 1.5;
const LABEL_MARGIN = 20;

const FIXED_SCREEN_HEIGHT_FACTORS: Record<
  Exclude<FleetchartScreenHeights, FleetchartScreenHeights.AUTO>,
  number
> = {
  "1x": 1,
  "1_5x": 1.5,
  "2x": 2,
  "3x": 3,
  "4x": 4,
};

const { t } = useI18n();

const mobile = useMobile();

const route = useRoute();

const comlink = useComlink();

const fleetchartStore = useFleetchartStore();

const layout = computed(() =>
  fleetchartStore.fleetchartLayout(props.namespace),
);

const viewpoint = computed(() =>
  fleetchartStore.fleetchartViewpoint(props.namespace),
);

const showLabels = computed(() => fleetchartStore.showLabels(props.namespace));

const colored = computed(() => fleetchartStore.colored(props.namespace));

const extended = computed(() => fleetchartStore.extendedState(props.namespace));

const selectedScreenHeight = computed(() =>
  fleetchartStore.fleetchartScreenHeight(props.namespace),
);

const savedZoom = computed(() =>
  fleetchartStore.fleetchartZoomData(props.namespace),
);

const screen = reactive({
  width: window.innerWidth,
  height: window.innerHeight,
});

const showStatus = ref(!!route.query?.showStatus);

const gridEnabled = ref(false);

const transform = shallowRef<Transform>({ x: 0, y: 0, scale: 1 });

const fontsLoaded = ref(false);

// Rebuilt once the webfont is in, as anything measured before used the fallback.
const labelMeasure = computed(() => {
  void fontsLoaded.value;

  const context = document.createElement("canvas").getContext("2d");
  const fontSize =
    parseFloat(getComputedStyle(document.body).fontSize) * LABEL_FONT_SCALE;
  const widths = new Map<string, number>();

  if (context) {
    context.font = `${fontSize}px Orbitron, sans-serif`;
  }

  return {
    lineHeight: fontSize * LABEL_LINE_HEIGHT,
    width: (text: string) => {
      if (!widths.has(text)) {
        widths.set(text, context?.measureText(text).width ?? 0);
      }

      return widths.get(text) as number;
    },
  };
});

const labelRoom = (entry: FleetchartEntry) => {
  if (!showLabels.value) {
    return { gutter: 0, minHeight: 0 };
  }

  const { title, subtitle } = shipLabelOf(entry);
  const lines = [
    title,
    subtitle,
    showStatus.value
      ? t(`labels.model.productionStatus.${modelOf(entry).productionStatus}`)
      : undefined,
  ].filter(Boolean) as string[];
  const { width, lineHeight } = labelMeasure.value;

  return {
    gutter:
      (Math.max(...lines.map(width)) + LABEL_MARGIN) / PIXELS_PER_METRE,
    minHeight: (lines.length * lineHeight) / PIXELS_PER_METRE,
  };
};

const ships = computed(() =>
  props.items.flatMap((entry) => {
    const geometry = shipGeometry(entry, viewpoint.value, {
      extended: extended.value,
      colored: colored.value,
    });

    if (!geometry) {
      return [];
    }

    return [
      {
        id: entry.id,
        entry,
        geometry,
        width: geometry.length,
        height: geometry.height,
        ...labelRoom(entry),
      },
    ];
  }),
);

const columnHeightFor = (factor: number) =>
  (screen.height * factor - SCREEN_MARGIN) / PIXELS_PER_METRE;

const screenHeightFactor = computed(() => {
  const selected = selectedScreenHeight.value;

  if (selected !== FleetchartScreenHeights.AUTO) {
    return FIXED_SCREEN_HEIGHT_FACTORS[selected];
  }

  return autoScreenHeightFactor(ships.value, screen, columnHeightFor);
});

const classicRowWidth = computed(
  () => (screen.width - SCREEN_MARGIN) / PIXELS_PER_METRE,
);

const positions = computed(() =>
  layout.value === FleetchartLayouts.CLASSIC
    ? arrangeClassic(ships.value, classicRowWidth.value)
    : arrangeColumns(ships.value, columnHeightFor(screenHeightFactor.value)),
);

const bounds = computed(() => {
  const covered = boundsOf(ships.value, positions.value);

  return layout.value === FleetchartLayouts.CLASSIC
    ? withRowWidth(covered, classicRowWidth.value)
    : covered;
});

const sceneX = (metres: number) =>
  (metres - bounds.value.minX) * PIXELS_PER_METRE + SCENE_PADDING;

const sceneY = (metres: number) =>
  (metres - bounds.value.minY) * PIXELS_PER_METRE + SCENE_PADDING;

const sceneSize = computed(() => ({
  width: bounds.value.width * PIXELS_PER_METRE + SCENE_PADDING * 2,
  height: bounds.value.height * PIXELS_PER_METRE + SCENE_PADDING * 2,
}));

const gridCell = computed(() =>
  gridCellFor(PIXELS_PER_METRE * transform.value.scale),
);

const metreLines = (min: number, extent: number) => {
  const first = Math.ceil(min / gridCell.value);
  const last = Math.floor((min + extent) / gridCell.value);

  return Array.from(
    { length: Math.max(last - first + 1, 0) },
    (_, index) => (first + index) * gridCell.value,
  );
};

// The on-screen grid is a sibling of the scene, so an export needs its own copy.
const exportGridLines = computed(() => {
  if (!gridEnabled.value) {
    return { vertical: [], horizontal: [] };
  }

  const margin = SCENE_PADDING / PIXELS_PER_METRE;

  return {
    vertical: metreLines(
      bounds.value.minX - margin,
      bounds.value.width + margin * 2,
    ).map(sceneX),
    horizontal: metreLines(
      bounds.value.minY - margin,
      bounds.value.height + margin * 2,
    ).map(sceneY),
  };
});

const gridCanvas = ref<HTMLCanvasElement>();

const drawGrid = async () => {
  if (!gridEnabled.value) {
    return;
  }

  await nextTick();

  const context = gridCanvas.value?.getContext("2d");

  if (!context) {
    return;
  }

  const { x, y, scale } = transform.value;
  const step = gridCell.value * PIXELS_PER_METRE * scale;
  const screenX = (metres: number) => x + sceneX(metres) * scale;
  const screenY = (metres: number) => y + sceneY(metres) * scale;

  context.clearRect(0, 0, screen.width, screen.height);
  context.fillStyle = "rgba(255, 255, 255, 0.5)";

  const offsetX = ((screenX(0) % step) + step) % step;
  const offsetY = ((screenY(0) % step) + step) % step;

  for (let left = offsetX; left < screen.width; left += step) {
    context.fillRect(Math.round(left), 0, 1, screen.height);
  }

  for (let top = offsetY; top < screen.height; top += step) {
    context.fillRect(0, Math.round(top), screen.width, 1);
  }
};

watch(
  [gridEnabled, transform, bounds, () => screen.width, () => screen.height],
  () => {
    void drawGrid();
  },
);

const scene = ref<HTMLElement>();

let panzoomInstance: PanZoom | undefined;

const persistZoom = debounce(() => {
  fleetchartStore.updateZoomData({
    namespace: props.namespace,
    zoomData: transform.value,
  });
}, 300);

const setupPanzoom = () => {
  if (!scene.value) {
    return;
  }

  panzoomInstance = panzoom(scene.value, {
    maxZoom: MAX_ZOOM,
    minZoom: MIN_ZOOM,
    zoomSpeed: 0.5,
    pinchSpeed: 3,
  });

  panzoomInstance.on("transform", () => {
    if (panzoomInstance) {
      transform.value = { ...panzoomInstance.getTransform() };
    }
  });

  panzoomInstance.on("zoom", persistZoom);
  panzoomInstance.on("pan", persistZoom);

  const { scale, x, y } = savedZoom.value;

  if (scale) {
    panzoomInstance.zoomAbs(0, 0, scale);

    // Zooming moves the scene around the given point, so the saved position only
    // holds once that has settled.
    setTimeout(() => {
      panzoomInstance?.moveTo(x, y);
    }, 300);
  }
};

const resetZoom = () => {
  panzoomInstance?.zoomAbs(0, 0, 1);
  panzoomInstance?.moveTo(0, 0);
};

// deviceorientation fires continuously on a phone, which would keep a plain
// debounce from ever running.
const handleResize = debounce(
  () => {
    screen.width = window.innerWidth;
    screen.height = window.innerHeight;
  },
  300,
  { maxWait: 1000 },
);

const toggleStatus = () => {
  showStatus.value = !showStatus.value;
};

let stopStatusListener: (() => void) | undefined;

onMounted(() => {
  void document.fonts?.ready.then(() => {
    fontsLoaded.value = true;
  });

  stopStatusListener = comlink.on("fleetchart-toggle-status", toggleStatus);

  setupPanzoom();

  window.addEventListener("resize", handleResize);
  window.addEventListener("deviceorientation", handleResize);
});

onUnmounted(() => {
  stopStatusListener?.();

  persistZoom.cancel();
  handleResize.cancel();

  panzoomInstance?.dispose();
  panzoomInstance = undefined;

  window.removeEventListener("resize", handleResize);
  window.removeEventListener("deviceorientation", handleResize);
});

const setViewpoint = (option: FleetchartViewpoints) => {
  fleetchartStore.updateViewpoint({
    namespace: props.namespace,
    viewpoint: option,
  });
};

const setScreenHeight = (option: FleetchartScreenHeights) => {
  fleetchartStore.updateScreenHeight({
    namespace: props.namespace,
    screenHeight: option,
  });
};

const toggleGrid = () => {
  gridEnabled.value = !gridEnabled.value;
};

const toggleColored = () => {
  fleetchartStore.toggleColored(props.namespace);
};

const toggleLabels = () => {
  fleetchartStore.toggleLabels(props.namespace);
};
</script>

<template>
  <div class="fleetchart-wrapper" data-test="fleetchart-canvas">
    <div class="fleetchart-controls">
      <BtnDropdown v-if="layout === FleetchartLayouts.COLUMNS">
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
          v-for="option in FleetchartScreenHeights"
          :key="option"
          :active="selectedScreenHeight === option"
          variant="bare"
          @click="setScreenHeight(option)"
        >
          {{ t(`labels.fleetchartApp.screenHeightOptions.${option}`) }}
        </Btn>
      </BtnDropdown>

      <BtnDropdown>
        <template #label>
          <template v-if="!mobile">
            {{ t("labels.fleetchartApp.viewpoint") }}:
          </template>
          {{ t(`labels.fleetchartApp.viewpointOptions.${viewpoint}`) }}
        </template>
        <Btn
          v-for="option in FleetchartViewpoints"
          :key="option"
          :active="viewpoint === option"
          variant="bare"
          @click="setViewpoint(option)"
        >
          {{ t(`labels.fleetchartApp.viewpointOptions.${option}`) }}
        </Btn>
      </BtnDropdown>

      <Btn
        :active="gridEnabled"
        data-test="fleetchart-grid"
        @click="toggleGrid"
      >
        <i class="fa-duotone fa-th" />
      </Btn>

      <Btn :active="colored" @click="toggleColored">
        <i class="fa-duotone fa-palette" />
      </Btn>

      <BtnDropdown>
        <template v-if="downloadName">
          <DownloadScreenshotBtn
            element="#fleetchart"
            :filename="downloadName"
          />

          <hr />
        </template>

        <Btn @click="toggleLabels">
          <i class="fa-duotone fa-tags" />
          <span v-if="showLabels">{{ t("actions.hideLabels") }}</span>
          <span v-else>{{ t("actions.showLabels") }}</span>
        </Btn>

        <FleetChartStatusBtn />

        <Btn @click="resetZoom">
          <i class="fa-duotone fa-undo" />
          <span>{{ t("actions.resetZoom") }}</span>
        </Btn>
      </BtnDropdown>
    </div>

    <div v-if="gridEnabled" class="fleetchart-canvas__grid-label">
      {{ t("labels.fleetchartApp.gridSize", { size: gridCell }) }}
    </div>

    <div class="fleetchart-canvas__viewport">
      <div
        id="fleetchart"
        ref="scene"
        class="fleetchart-canvas__scene"
        :style="{
          width: `${sceneSize.width}px`,
          height: `${sceneSize.height}px`,
        }"
      >
        <template v-if="gridEnabled">
          <div
            v-for="left in exportGridLines.vertical"
            :key="`vertical-${left}`"
            class="fleetchart-canvas__export-only fleetchart-canvas__export-line"
            :style="{
              left: `${left}px`,
              top: 0,
              bottom: 0,
              width: '1px',
            }"
          />
          <div
            v-for="top in exportGridLines.horizontal"
            :key="`horizontal-${top}`"
            class="fleetchart-canvas__export-only fleetchart-canvas__export-line"
            :style="{
              top: `${top}px`,
              left: 0,
              right: 0,
              height: '1px',
            }"
          />
        </template>

        <FleetchartCanvasItem
          v-for="ship in ships"
          :key="ship.id"
          :entry="ship.entry"
          :geometry="ship.geometry"
          :left="sceneX(positions[ship.id].x - ship.width / 2)"
          :top="sceneY(positions[ship.id].y - ship.height / 2)"
          :viewpoint="viewpoint"
          :zoom="savedZoom.scale || 1"
          :show-label="showLabels"
          :show-status="showStatus"
          :colored="colored"
          :extended="extended"
        />

        <div
          class="fleetchart-canvas__export-only fleetchart-canvas__export-logo"
        >
          <CommunityLogo />
        </div>
      </div>

      <canvas
        v-if="gridEnabled"
        ref="gridCanvas"
        class="fleetchart-canvas__grid"
        :width="screen.width"
        :height="screen.height"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "index.scss";
</style>
