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
import FleetchartCanvasShipControls from "./ShipControls/index.vue";
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
  arrangeFree,
  arrangePacked,
  snapToGrid,
  autoScreenHeightFactor,
  boundsOf,
  gridCellFor,
  groupHeadings,
  withHeadings,
  type FleetchartHeadingAlign,
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
  type FleetchartPlacements,
} from "@/shared/stores/fleetchart";

interface Props {
  namespace: string;
  items?: FleetchartEntry[];
  downloadName?: string;
  // Whether this chart offers the free layout, which needs a whole fleet to work on.
  canArrange?: boolean;
  // False until `items` holds everything that can be arranged.
  arrangeReady?: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  downloadName: undefined,
  canArrange: false,
  arrangeReady: true,
});

const SCENE_PADDING = 40;
const SCREEN_MARGIN = 120;
const MIN_ZOOM = 0.02;
// An export is always drawn at full size, so its grid cannot follow the zoom.
const EXPORT_GRID_CELL = gridCellFor(PIXELS_PER_METRE);
const EXPORT_IMAGE_TIMEOUT = 15000;
const SHIP_CONTROLS_GAP = 10;
const SHIP_CONTROLS_MARGIN = 200;
const SHIP_CONTROLS_MIN_TOP = 130;
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
  fleetchartStore.fleetchartLayout(props.namespace, props.canArrange),
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

// Read one by one so that a toggle unrelated to the layout, such as the scale bar,
// does not lay out the whole fleet again.
const sort = computed(() => options.value.sort);
const group = computed(() => options.value.group);
const spacing = computed(() => options.value.spacing);
const facing = computed(() => options.value.facing);

const turned = computed(
  () =>
    facing.value === FleetchartFacings.TOP ||
    facing.value === FleetchartFacings.BOTTOM,
);

// What a layout makes room for. A ship's own box is as tall as its tallest view
// so nothing moves between viewpoints, but a packed or turned chart is about using
// the space, so there only the view being drawn counts.
const boxOf = (
  geometry: FleetchartShipGeometry,
  shipFacing: FleetchartFacings,
  tight: boolean,
) => {
  const drawn = geometry.imageHeight || geometry.height;

  if (
    shipFacing === FleetchartFacings.TOP ||
    shipFacing === FleetchartFacings.BOTTOM
  ) {
    return { width: drawn, height: geometry.length };
  }

  return { width: geometry.length, height: tight ? drawn : geometry.height };
};

const fillsSpaceIn = (kind: FleetchartLayouts) =>
  kind === FleetchartLayouts.FREE || kind === FleetchartLayouts.PACKED;

const isFree = computed(() => layout.value === FleetchartLayouts.FREE);

const fillsSpace = computed(() => fillsSpaceIn(layout.value));

const placements = computed(() =>
  fleetchartStore.fleetchartPlacements(props.namespace),
);

const facingOf = (id: string) => placements.value[id]?.facing ?? facing.value;

const groupTitle = (entry: FleetchartEntry) => {
  if (group.value === FleetchartGroups.NONE) {
    return undefined;
  }

  return (
    groupTitleOf(entry, group.value, t) ||
    t("labels.fleetchartApp.groupOptions.none")
  );
};

// The ships as a given layout sees them, which is not only the active one: a free
// arrangement starts from the layout before it, whose boxes and groups differ.
const shipsFor = (kind: FleetchartLayouts) => {
  const free = kind === FleetchartLayouts.FREE;

  return sortEntries(
    props.items,
    sort.value,
    group.value,
    extended.value,
  ).flatMap((entry) => {
    const shipViewpoint =
      (free && placements.value[entry.id]?.viewpoint) || viewpoint.value;
    const geometry = shipGeometry(entry, shipViewpoint, {
      extended: extended.value,
      colored: colored.value,
    });

    if (!geometry) {
      return [];
    }

    const shipFacing = free ? facingOf(entry.id) : facing.value;
    const placed = !!placements.value[entry.id];
    const shipGroup = free
      ? placed
        ? undefined
        : t("labels.fleetchartApp.unplaced")
      : groupTitle(entry);

    return [
      {
        id: entry.id,
        entry,
        geometry,
        ...boxOf(geometry, shipFacing, fillsSpaceIn(kind)),
        facing: shipFacing,
        viewpoint: shipViewpoint,
        group: shipGroup,
        headingWidth: shipGroup
          ? labelMeasure.value.width(shipGroup) / PIXELS_PER_METRE
          : 0,
        padding: SHIP_PADDING * SPACING_FACTORS[spacing.value],
        ...labelRoom(entry),
      },
    ];
  });
};

type CanvasShip = ReturnType<typeof shipsFor>[number];

const ships = computed(() => shipsFor(layout.value));

const columnHeightFor = (factor: number) =>
  (screen.height * factor - SCREEN_MARGIN) / PIXELS_PER_METRE;

const screenHeightFactorFor = (list: CanvasShip[]) => {
  const selected = selectedScreenHeight.value;

  if (selected !== FleetchartScreenHeights.AUTO) {
    return FIXED_SCREEN_HEIGHT_FACTORS[selected];
  }

  return autoScreenHeightFactor(list, screen, columnHeightFor);
};

const classicRowWidth = computed(
  () => (screen.width - SCREEN_MARGIN) / PIXELS_PER_METRE,
);

const packedAspect = computed(
  () => screen.width / (screen.height - FIT_MARGIN_TOP - FIT_MARGIN_BOTTOM),
);

const arrange = (kind: FleetchartLayouts, list: CanvasShip[]) => {
  switch (kind) {
    case FleetchartLayouts.CLASSIC:
      return arrangeClassic(list, classicRowWidth.value);
    case FleetchartLayouts.PACKED:
      return arrangePacked(list, packedAspect.value);
    case FleetchartLayouts.COLUMNS:
      return arrangeColumns(
        list,
        columnHeightFor(screenHeightFactorFor(list)),
        {
          centred: turned.value,
        },
      );
    default:
      return arrangeFree(list, placements.value, classicRowWidth.value);
  }
};

const dragged = shallowRef<{ id: string; x: number; y: number }>();

const arranged = computed(() => arrange(layout.value, ships.value));

const positions = computed(() =>
  dragged.value
    ? {
        ...arranged.value,
        [dragged.value.id]: { x: dragged.value.x, y: dragged.value.y },
      }
    : arranged.value,
);

const headingAlign = computed<FleetchartHeadingAlign>(() => {
  if (layout.value !== FleetchartLayouts.COLUMNS) {
    return "left";
  }

  return turned.value ? "centre" : "right";
});

const headings = computed(() =>
  groupHeadings(ships.value, positions.value, headingAlign.value),
);

const bounds = computed(() => {
  const covered = withHeadings(
    boundsOf(ships.value, positions.value),
    headings.value,
  );

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

// The on-screen grid is a sibling of the scene, so an export needs its own copy.
const exportGridStyle = computed(() => {
  const line = "rgba(255, 255, 255, 0.5) 1px, transparent 1px";
  const cell = EXPORT_GRID_CELL * PIXELS_PER_METRE;
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

const exporting = ref(false);

// The images drawn while zoomed out are too small for a full-size export, so the
// larger ones are only fetched for as long as an export needs them.
const prepareExport = async () => {
  exporting.value = true;

  await nextTick();

  const images = [...(scene.value?.querySelectorAll("img") ?? [])];

  await Promise.race([
    Promise.all(images.map((image) => image.decode().catch(() => {}))),
    new Promise((resolve) => {
      setTimeout(resolve, EXPORT_IMAGE_TIMEOUT);
    }),
  ]);
};

const finishExport = () => {
  exporting.value = false;
};

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

let restoreTimer: ReturnType<typeof setTimeout> | undefined;

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
    // A press on a ship being arranged moves that ship, not the chart.
    beforeMouseDown: (event) =>
      isFree.value &&
      (event.target as Element).closest("[data-test='fleetchart-ship']")
        ? true
        : undefined,
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

  // These always open whole, as their size depends on the fleet and the screen.
  if (fillsSpace.value) {
    fitToScreen();

    return;
  }

  const { scale, x, y } = savedZoom.value;

  if (scale) {
    panzoomInstance.zoomAbs(0, 0, scale);

    // Zooming moves the scene around the given point, so the saved position only
    // holds once that has settled.
    restoreTimer = setTimeout(() => {
      panzoomInstance?.moveTo(x, y);
    }, 300);
  }
};

const isPacked = computed(() => layout.value === FleetchartLayouts.PACKED);

// Packing is only worth anything when the whole of it can be seen at once.
const fitToScreen = () => {
  clearTimeout(restoreTimer);

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
  clearTimeout(restoreTimer);

  if (fillsSpace.value) {
    fitToScreen();

    return;
  }

  panzoomInstance?.zoomAbs(0, 0, 1);
  panzoomInstance?.moveTo(0, 0);

  persistZoom();
};

// A position from one layout can leave another one entirely off screen.
watch(layout, resetZoom);

watch([() => sceneSize.value.width, () => sceneSize.value.height], () => {
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

// The scene is drawn from its bounds, so an edit growing them to the left or top
// would shift every ship on screen. Moving the view the other way holds them still.
const holdingView = (edit: () => void) => {
  const { minX, minY } = bounds.value;

  edit();

  if (!panzoomInstance) {
    return;
  }

  const { x, y, scale } = panzoomInstance.getTransform();

  panzoomInstance.moveTo(
    x + (bounds.value.minX - minX) * PIXELS_PER_METRE * scale,
    y + (bounds.value.minY - minY) * PIXELS_PER_METRE * scale,
  );
};

const FACING_CYCLE = Object.values(FleetchartFacings);
const UNDO_LIMIT = 50;

const selectedId = ref<string>();

const undoStack = shallowRef<FleetchartPlacements[]>([]);

const savePlacements = (next: FleetchartPlacements) => {
  fleetchartStore.updatePlacements({
    namespace: props.namespace,
    placements: next,
  });
};

const changePlacements = (next: FleetchartPlacements) => {
  undoStack.value = [...undoStack.value, placements.value].slice(-UNDO_LIMIT);

  savePlacements(next);
};

const undo = () => {
  const previous = undoStack.value[undoStack.value.length - 1];

  if (previous) {
    undoStack.value = undoStack.value.slice(0, -1);

    holdingView(() => savePlacements(previous));
  }
};

// Every ship gets a place at once, as the given layout has it, so the arrangement
// starts out as what was showing and no ship moves when the first one is dragged.
const placeAll = (kind: FleetchartLayouts): FleetchartPlacements => {
  const list = shipsFor(kind);
  const from = arrange(kind, list);

  return Object.fromEntries(
    list.map((ship) => [ship.id, { ...from[ship.id], facing: facing.value }]),
  );
};

let seedLayout = FleetchartLayouts.PACKED;

watch(
  layout,
  (_current, previous) => {
    if (previous && previous !== FleetchartLayouts.FREE) {
      seedLayout = previous;
    }
  },
  { flush: "sync" },
);

watch(
  [isFree, () => props.arrangeReady, () => ships.value.length],
  () => {
    if (
      isFree.value &&
      props.arrangeReady &&
      ships.value.length &&
      !Object.keys(placements.value).length
    ) {
      savePlacements(placeAll(seedLayout));
      fitToScreen();
    }
  },
  { immediate: true },
);

const resetArrangement = () => {
  // Merged, as ships hidden by a filter keep their place.
  changePlacements({ ...placements.value, ...placeAll(seedLayout) });
  fitToScreen();
};

const selectedShip = computed(() =>
  isFree.value
    ? ships.value.find((ship) => ship.id === selectedId.value)
    : undefined,
);

const changeSelected = (changes: {
  facing?: FleetchartFacings;
  viewpoint?: FleetchartViewpoints;
}) => {
  const id = selectedShip.value?.id;
  const current = id ? positions.value[id] : undefined;

  if (!id || !current) {
    return;
  }

  holdingView(() => {
    changePlacements({
      ...placements.value,
      [id]: {
        ...placements.value[id],
        x: current.x,
        y: current.y,
        ...changes,
      },
    });
  });
};

const rotateSelected = () => {
  if (selectedShip.value) {
    const index = FACING_CYCLE.indexOf(selectedShip.value.facing);

    changeSelected({
      facing: FACING_CYCLE[(index + 1) % FACING_CYCLE.length],
    });
  }
};

// Drawn over the scene rather than in it, so it stays readable at any zoom and
// never reaches an export.
const shipControlsStyle = computed(() => {
  const ship = selectedShip.value;
  const position = ship ? positions.value[ship.id] : undefined;

  if (!ship || !position) {
    return undefined;
  }

  const { x, y, scale } = transform.value;
  const top = y + sceneY(position.y - ship.height / 2) * scale;
  const bottom = y + sceneY(position.y + ship.height / 2) * scale;
  const above = top > SHIP_CONTROLS_MIN_TOP;

  return {
    left: `${Math.min(
      Math.max(x + sceneX(position.x) * scale, SHIP_CONTROLS_MARGIN),
      screen.width - SHIP_CONTROLS_MARGIN,
    )}px`,
    top: `${above ? top - SHIP_CONTROLS_GAP : bottom + SHIP_CONTROLS_GAP}px`,
    transform: `translate(-50%, ${above ? "-100%" : "0"})`,
  };
});

const deselectOutsideShip = (event: PointerEvent) => {
  if (!(event.target as Element).closest("[data-test='fleetchart-ship']")) {
    selectedId.value = undefined;
  }
};

let stopDrag: (() => void) | undefined;

const startDrag = (id: string, event: PointerEvent) => {
  if (!isFree.value || event.pointerType === "touch" || event.button !== 0) {
    return;
  }

  event.preventDefault();
  selectedId.value = id;

  const ship = ships.value.find((candidate) => candidate.id === id);
  const start = positions.value[id];

  if (!ship || !start) {
    return;
  }

  stopDrag?.();

  // Keeps the drag alive when the pointer leaves the window.
  (event.target as Element).setPointerCapture?.(event.pointerId);

  const { clientX, clientY } = event;

  const onMove = (move: PointerEvent) => {
    const metresPerPixel = 1 / (PIXELS_PER_METRE * transform.value.scale);
    const moved = {
      x: start.x + (move.clientX - clientX) * metresPerPixel,
      y: start.y + (move.clientY - clientY) * metresPerPixel,
    };

    holdingView(() => {
      dragged.value = {
        id,
        ...(gridEnabled.value
          ? snapToGrid(moved, ship, gridCell.value)
          : moved),
      };
    });
  };

  const onUp = () => {
    const dropped = dragged.value;

    stopDrag?.();

    if (dropped) {
      holdingView(() => {
        dragged.value = undefined;
        changePlacements({
          ...placements.value,
          [id]: {
            ...placements.value[id],
            x: dropped.x,
            y: dropped.y,
            facing: facingOf(id),
          },
        });
      });
    }
  };

  const onCancel = () => {
    stopDrag?.();
    holdingView(() => {
      dragged.value = undefined;
    });
  };

  stopDrag = () => {
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
    window.removeEventListener("pointercancel", onCancel);
    stopDrag = undefined;
  };

  window.addEventListener("pointermove", onMove);
  window.addEventListener("pointerup", onUp);
  window.addEventListener("pointercancel", onCancel);
};

const isEditable = (target: EventTarget | null) =>
  target instanceof HTMLElement &&
  (target.isContentEditable ||
    ["INPUT", "SELECT", "TEXTAREA"].includes(target.tagName));

const handleArrangeKeys = (event: KeyboardEvent) => {
  if (!isFree.value || isEditable(event.target)) {
    return;
  }

  if ((event.metaKey || event.ctrlKey) && event.key === "z") {
    event.preventDefault();
    undo();
  } else if (event.key === "Escape") {
    selectedId.value = undefined;
  } else if (event.key === "r" && !event.metaKey && !event.ctrlKey) {
    rotateSelected();
  }
};

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

  window.addEventListener("keydown", handleArrangeKeys);
  window.addEventListener("resize", handleResize);
  window.addEventListener("deviceorientation", handleResize);
});

onUnmounted(() => {
  stopStatusListener?.();

  clearTimeout(restoreTimer);
  stopDrag?.();
  persistZoom.flush();
  handleResize.cancel();

  panzoomInstance?.dispose();
  panzoomInstance = undefined;

  window.removeEventListener("keydown", handleArrangeKeys);
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
      <template v-if="isFree">
        <Btn
          v-tooltip="t('labels.fleetchartApp.undo')"
          :aria-label="t('labels.fleetchartApp.undo')"
          :disabled="!undoStack.length"
          data-test="fleetchart-undo"
          @click="undo"
        >
          <i class="fa-duotone fa-rotate-left" />
        </Btn>
        <Btn
          v-tooltip="t('labels.fleetchartApp.resetArrangement')"
          :aria-label="t('labels.fleetchartApp.resetArrangement')"
          data-test="fleetchart-reset-arrangement"
          @click="resetArrangement"
        >
          <i class="fa-duotone fa-arrows-rotate" />
        </Btn>
      </template>

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
            :prepare="prepareExport"
            :finish="finishExport"
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

    <FleetchartCanvasSettings
      v-if="settingsOpen"
      :namespace="namespace"
      :can-arrange="canArrange"
    />

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

    <FleetchartCanvasShipControls
      v-if="selectedShip && !dragged && !exporting"
      :viewpoint="selectedShip.viewpoint"
      :style="shipControlsStyle"
      @rotate="rotateSelected"
      @update:viewpoint="changeSelected({ viewpoint: $event })"
    />

    <div class="fleetchart-canvas__viewport" @pointerdown="deselectOutsideShip">
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
          :viewpoint="ship.viewpoint"
          :zoom="exporting ? 1 : savedZoom.scale || 1"
          :show-label="showLabels"
          :show-status="showStatus"
          :colored="colored"
          :extended="extended"
          :box-width="ship.width"
          :box-height="ship.height"
          :facing="ship.facing"
          :selected="isFree && !exporting && selectedId === ship.id"
          :arranging="isFree"
          @pointerdown="startDrag(ship.id, $event)"
        />

        <div
          v-if="options.scaleBar"
          class="fleetchart-canvas__export-only fleetchart-canvas__export-scale"
        >
          <span
            class="fleetchart-canvas__scale-bar"
            :style="{ width: `${EXPORT_GRID_CELL * PIXELS_PER_METRE}px` }"
          />
          {{ EXPORT_GRID_CELL }} m
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
