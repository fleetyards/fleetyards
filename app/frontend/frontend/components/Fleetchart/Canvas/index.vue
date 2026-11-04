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
import FleetchartCanvasSettings from "./Settings/index.vue";
import {
  PIXELS_PER_METRE,
  modelOf,
  shipGeometry,
  shipLabelOf,
  type FleetchartEntry,
  type FleetchartShipGeometry,
} from "@/frontend/components/Fleetchart/geometry";
import {
  arrangeClassic,
  arrangeColumns,
  arrangePacked,
  autoScreenHeightFactor,
  boundsOf,
  gridCellFor,
  groupHeadings,
  SHIP_PADDING,
  withRowWidth,
} from "@/frontend/components/Fleetchart/layouts";
import {
  groupTitleOf,
  sortEntries,
} from "@/frontend/components/Fleetchart/options";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import {
  FleetchartFacings,
  FleetchartGroups,
  FleetchartLayouts,
  FleetchartScreenHeights,
  FleetchartSpacings,
  FleetchartViewpoints,
  useFleetchartStore,
} from "@/shared/stores/fleetchart";

interface Props {
  namespace: string;
  items?: FleetchartEntry[];
  downloadName?: string;
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  downloadName: undefined,
});

const SCENE_PADDING = 40;
const SCREEN_MARGIN = 120;
const MIN_ZOOM = 0.02;
const FIT_MARGIN_TOP = 70;
const FIT_MARGIN_BOTTOM = 80;
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

const SPACING_FACTORS: Record<FleetchartSpacings, number> = {
  [FleetchartSpacings.COMPACT]: 0.4,
  [FleetchartSpacings.NORMAL]: 1,
  [FleetchartSpacings.WIDE]: 3,
};

const SOLID_EXPORT_BACKGROUND = "#111";

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

const options = computed(() =>
  fleetchartStore.fleetchartOptions(props.namespace),
);

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
    gutter: (Math.max(...lines.map(width)) + LABEL_MARGIN) / PIXELS_PER_METRE,
    minHeight: (lines.length * lineHeight) / PIXELS_PER_METRE,
  };
};

const turned = computed(
  () =>
    options.value.facing === FleetchartFacings.TOP ||
    options.value.facing === FleetchartFacings.BOTTOM,
);

// What a layout makes room for. A ship's own box is as tall as its tallest view
// so nothing moves between viewpoints, but a packed or turned chart is about using
// the space, so there only the view being drawn counts.
const boxOf = (geometry: FleetchartShipGeometry) => {
  const drawn = geometry.imageHeight || geometry.height;

  if (turned.value) {
    return { width: drawn, height: geometry.length };
  }

  return {
    width: geometry.length,
    height: layout.value === FleetchartLayouts.PACKED ? drawn : geometry.height,
  };
};

const groupTitle = (entry: FleetchartEntry) => {
  if (options.value.group === FleetchartGroups.NONE) {
    return undefined;
  }

  return (
    groupTitleOf(entry, options.value.group, t) ||
    t("labels.fleetchartApp.groupOptions.none")
  );
};

const ships = computed(() =>
  sortEntries(props.items, options.value.sort, options.value.group).flatMap(
    (entry) => {
      const geometry = shipGeometry(entry, viewpoint.value, {
        extended: extended.value,
        colored: colored.value,
      });

      if (!geometry) {
        return [];
      }

      const group = groupTitle(entry);

      return [
        {
          id: entry.id,
          entry,
          geometry,
          ...boxOf(geometry),
          group,
          headingWidth: group
            ? labelMeasure.value.width(group) / PIXELS_PER_METRE
            : 0,
          padding: SHIP_PADDING * SPACING_FACTORS[options.value.spacing],
          ...labelRoom(entry),
        },
      ];
    },
  ),
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

const positions = computed(() => {
  switch (layout.value) {
    case FleetchartLayouts.CLASSIC:
      return arrangeClassic(ships.value, classicRowWidth.value);
    case FleetchartLayouts.PACKED:
      return arrangePacked(ships.value, screen.width / screen.height);
    default:
      return arrangeColumns(
        ships.value,
        columnHeightFor(screenHeightFactor.value),
        { centred: turned.value },
      );
  }
});

const bounds = computed(() => {
  const covered = boundsOf(ships.value, positions.value);

  return layout.value === FleetchartLayouts.CLASSIC
    ? withRowWidth(covered, classicRowWidth.value)
    : covered;
});

const headings = computed(() => groupHeadings(ships.value, positions.value));

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

// The on-screen grid is a sibling of the scene, so an export needs its own copy.
const exportGridStyle = computed(() => {
  const line = "rgba(255, 255, 255, 0.5) 1px, transparent 1px";
  const cell = gridCell.value * PIXELS_PER_METRE;
  const offset = (position: number) => ((position % cell) + cell) % cell;

  return {
    backgroundImage: `linear-gradient(${line}), linear-gradient(90deg, ${line})`,
    backgroundSize: `${cell}px ${cell}px`,
    backgroundPosition: `${offset(sceneX(0))}px ${offset(sceneY(0))}px`,
  };
});

const scaleBarWidth = computed(
  () => gridCell.value * PIXELS_PER_METRE * transform.value.scale,
);

const settingsOpen = ref(false);

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

const isPacked = computed(() => layout.value === FleetchartLayouts.PACKED);

// Packing is only worth anything when the whole of it can be seen at once.
const fitToScreen = () => {
  const room = screen.height - FIT_MARGIN_TOP - FIT_MARGIN_BOTTOM;
  const scale = Math.min(
    1,
    screen.width / sceneSize.value.width,
    room / sceneSize.value.height,
  );

  panzoomInstance?.zoomAbs(0, 0, scale);
  panzoomInstance?.moveTo(
    (screen.width - sceneSize.value.width * scale) / 2,
    FIT_MARGIN_TOP + (room - sceneSize.value.height * scale) / 2,
  );

  persistZoom();
};

const resetZoom = () => {
  if (isPacked.value) {
    fitToScreen();

    return;
  }

  panzoomInstance?.zoomAbs(0, 0, 1);
  panzoomInstance?.moveTo(0, 0);

  persistZoom();
};

// A position from one layout can leave another one entirely off screen.
watch(layout, resetZoom);

watch(sceneSize, () => {
  if (isPacked.value) {
    fitToScreen();
  }
});

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

  persistZoom.flush();
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

      <Btn
        :active="settingsOpen"
        :aria-label="t('labels.fleetchartApp.options')"
        data-test="fleetchart-options"
        @click="settingsOpen = !settingsOpen"
      >
        <i class="fa-duotone fa-sliders" />
      </Btn>

      <BtnDropdown>
        <template v-if="downloadName">
          <DownloadScreenshotBtn
            element="#fleetchart"
            :filename="downloadName"
            :background-color="
              options.solidExport ? SOLID_EXPORT_BACKGROUND : null
            "
            ignore-transform
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

    <FleetchartCanvasSettings v-if="settingsOpen" :namespace="namespace" />

    <div
      v-if="options.scaleBar"
      class="fleetchart-canvas__scale"
      data-test="fleetchart-scale"
    >
      <span
        class="fleetchart-canvas__scale-bar"
        :style="{ width: `${scaleBarWidth}px` }"
      />
      {{ gridCell }} m
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
        <div
          v-if="gridEnabled"
          class="fleetchart-canvas__export-only fleetchart-canvas__export-grid"
          :style="exportGridStyle"
        />

        <div
          v-for="heading in headings"
          :key="heading.title"
          class="fleetchart-canvas__heading"
          :style="{
            left: `${sceneX(heading.x)}px`,
            top: `${sceneY(heading.y)}px`,
          }"
          data-test="fleetchart-group-heading"
        >
          {{ heading.title }}
        </div>

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
          :box-width="ship.width"
          :box-height="ship.height"
          :facing="options.facing"
        />

        <div
          v-if="options.scaleBar"
          class="fleetchart-canvas__export-only fleetchart-canvas__export-scale"
        >
          <span
            class="fleetchart-canvas__scale-bar"
            :style="{ width: `${gridCell * PIXELS_PER_METRE}px` }"
          />
          {{ gridCell }} m
        </div>

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
