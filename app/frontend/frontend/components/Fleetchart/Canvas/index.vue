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
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import CommunityLogo from "@/shared/components/CommunityLogo/index.vue";
import pyroNebula from "@/images/skyboxes/pyro_nebula_2k.webp";
import stantonNebula from "@/images/skyboxes/stanton_nebula_spherical_2k.webp";
import crusaderNebula from "@/images/skyboxes/stanton_crusader_nebula_2k.webp";
import DownloadScreenshotBtn from "@/frontend/components/DownloadScreenshotBtn/index.vue";
import FleetChartStatusBtn from "@/frontend/components/FleetChartStatusBtn/index.vue";
import FleetchartCanvasProgress from "./Progress/index.vue";
import FleetchartCanvasItem from "./Item/index.vue";
import FleetchartCanvasSavedLayouts from "./SavedLayouts/index.vue";
import FleetchartCanvasSettings from "./Settings/index.vue";
import FleetchartCanvasShipControls from "./ShipControls/index.vue";
import {
  PIXELS_PER_METRE,
  modelOf,
  shipGeometry,
  hasStateViews,
  shipLabelOf,
  viewFor,
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
  type FleetchartPositions,
} from "@/frontend/components/Fleetchart/layouts";
import { isCatalogueEntry } from "@/frontend/components/Fleetchart/catalogueShips";
import { createImageProgress } from "@/frontend/components/Fleetchart/imageProgress";
import { createExportProgress } from "@/frontend/components/Fleetchart/exportProgress";
import type { DownloadScreenshotStage } from "@/frontend/components/DownloadScreenshotBtn/types";
import {
  BASE_GROUPS,
  effectiveGroup,
  groupTitleOf,
  sortEntries,
} from "@/frontend/components/Fleetchart/options";
import {
  placementsFromLayout,
  stackingOrders,
  type FleetchartPlacementInput,
} from "@/frontend/components/Fleetchart/savedLayouts";
import type {
  FleetchartCataloguePlacement,
  FleetchartLayout,
} from "@/services/fyApi";
import type { ModelPickerSelection } from "@/frontend/components/Models/PickerModal/types";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import {
  FleetchartBackgrounds,
  FleetchartFacings,
  FleetchartGroups,
  FleetchartHeadingSizes,
  FleetchartLayouts,
  FleetchartScreenHeights,
  FleetchartShipStates,
  FleetchartSpacings,
  FleetchartViewpoints,
  useFleetchartStore,
  type FleetchartPlacement,
  type FleetchartPlacements,
} from "@/shared/stores/fleetchart";

interface Props {
  namespace: string;
  items?: FleetchartEntry[];
  downloadName?: string;
  // Whether this chart offers the free layout, which needs a whole fleet to work on.
  canArrange?: boolean;
  readOnly?: boolean;
  // False until `items` holds everything that can be arranged.
  arrangeReady?: boolean;
  groups?: FleetchartGroups[];
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  downloadName: undefined,
  canArrange: false,
  readOnly: false,
  arrangeReady: true,
  groups: () => BASE_GROUPS,
});

const SCENE_PADDING = 40;
const SCREEN_MARGIN = 120;
const MIN_ZOOM = 0.02;
// An export is always drawn at full size, so its grid cannot follow the zoom.
const EXPORT_GRID_CELL = gridCellFor(PIXELS_PER_METRE);
const EXPORT_IMAGE_TIMEOUT = 15000;
const SHIP_CONTROLS_GAP = 10;
const SHIP_CONTROLS_MARGIN = 10;
const SHIP_CONTROLS_MIN_TOP = 130;
const FIT_MARGIN_TOP = 70;
const FIT_MARGIN_BOTTOM = 80;
const MAX_ZOOM = 20;
const LABEL_FONT_SCALE = 1.2;
const LABEL_LINE_HEIGHT = 1.5;
const LABEL_MARGIN = 20;
// A heading starts at the size of a page's own headline.
const HEADING_FONT_REM = 1.5;
const HEADING_LINE_HEIGHT = 2;
const HEADING_SIZE_FACTORS: Record<
  Exclude<FleetchartHeadingSizes, FleetchartHeadingSizes.FLEET>,
  number
> = {
  normal: 1,
  large: 2,
  extraLarge: 4,
};
// Growing with the fleet keeps the base size up to this many ships, then follows
// the square root of the count, as the chart's sides do, so a heading stays the
// same size against the ships around it however many there are.
const HEADING_BASE_SHIPS = 25;
const MAX_HEADING_GROWTH = 20;
const MAX_SHADOWED_SHIPS = 250;
// Ships added one after another would otherwise land exactly on top of each other.
const ADDED_SHIP_OFFSET = 8;
const ADDED_SHIP_OFFSETS = 6;

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

const BACKGROUND_IMAGES: Partial<Record<FleetchartBackgrounds, string>> = {
  [FleetchartBackgrounds.STANTON]: stantonNebula,
  [FleetchartBackgrounds.CRUSADER]: crusaderNebula,
  [FleetchartBackgrounds.PYRO]: pyroNebula,
};

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

const colored = computed(() =>
  fleetchartStore.coloredByDefault(props.namespace),
);

// The one place a stored group meets what this chart offers: one chosen on a
// fleet's chart reads as none on a chart without captains or squadrons.
const options = computed(() => {
  const stored = fleetchartStore.fleetchartOptions(props.namespace);

  return { ...stored, group: effectiveGroup(stored.group, props.groups) };
});

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
    fontSize,
    lineHeight: fontSize * LABEL_LINE_HEIGHT,
    width: (text: string) => {
      if (!widths.has(text)) {
        widths.set(text, context?.measureText(text).width ?? 0);
      }

      return widths.get(text) as number;
    },
  };
});

const headingGrowth = computed(() => {
  const size = options.value.headingSize;

  if (size === FleetchartHeadingSizes.FLEET) {
    return Math.min(
      MAX_HEADING_GROWTH,
      Math.max(1, Math.sqrt(props.items.length / HEADING_BASE_SHIPS)),
    );
  }

  return HEADING_SIZE_FACTORS[size] ?? 1;
});

const headingFontSize = computed(
  () =>
    parseFloat(getComputedStyle(document.documentElement).fontSize) *
    HEADING_FONT_REM *
    headingGrowth.value,
);

// Measured in the label font and scaled, as the heading uses the same face.
const headingRoomFor = (title: string) => ({
  headingWidth:
    (labelMeasure.value.width(title) *
      (headingFontSize.value / labelMeasure.value.fontSize)) /
    PIXELS_PER_METRE,
  headingRoom: (headingFontSize.value * HEADING_LINE_HEIGHT) / PIXELS_PER_METRE,
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
const state = computed(() => options.value.state);

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
  const drawnHeight = geometry.imageHeight || geometry.height;
  const drawnWidth = tight
    ? geometry.imageWidth || geometry.length
    : geometry.frameWidth;

  if (
    shipFacing === FleetchartFacings.TOP ||
    shipFacing === FleetchartFacings.BOTTOM
  ) {
    return { width: drawnHeight, height: drawnWidth };
  }

  return { width: drawnWidth, height: tight ? drawnHeight : geometry.height };
};

const fillsSpaceIn = (kind: FleetchartLayouts) =>
  kind === FleetchartLayouts.FREE || kind === FleetchartLayouts.PACKED;

const isFree = computed(() => layout.value === FleetchartLayouts.FREE);

const arranging = computed(() => isFree.value && !props.readOnly);

const fillsSpace = computed(() => fillsSpaceIn(layout.value));

const placements = computed(() =>
  fleetchartStore.fleetchartPlacements(props.namespace),
);

const facingOf = (id: string) => placements.value[id]?.facing ?? facing.value;

// A captain is missing only when they chose not to be shown.
const emptyGroupTitle = (option: FleetchartGroups) => {
  switch (option) {
    case FleetchartGroups.SQUADRON:
      return t("labels.fleetchartApp.noSquadron");
    case FleetchartGroups.CAPTAIN:
      return t("labels.fleetchartApp.unknownCaptain");
    default:
      return t("labels.fleetchartApp.groupOptions.none");
  }
};

const groupTitle = (entry: FleetchartEntry) => {
  if (group.value === FleetchartGroups.NONE) {
    return undefined;
  }

  return groupTitleOf(entry, group.value, t) || emptyGroupTitle(group.value);
};

// Not every ship has every view, and one without the chosen view is shown from one
// it has rather than left blank.
const drawableViewpoint = (
  entry: FleetchartEntry,
  wanted: FleetchartViewpoints,
  shipState: FleetchartShipStates,
) => {
  const has = (option: FleetchartViewpoints) =>
    viewFor(entry, option, { state: shipState, colored: colored.value });

  return (
    [
      wanted,
      FleetchartViewpoints.PORT,
      FleetchartViewpoints.TOP,
      FleetchartViewpoints.ANGLED,
    ].find(has) ?? wanted
  );
};

// The ships as a given layout sees them, which is not only the active one: a free
// arrangement starts from the layout before it, whose boxes and groups differ.
const shipsFor = (kind: FleetchartLayouts, keepShipSettings = false) => {
  const free = kind === FleetchartLayouts.FREE;
  const ownSettings = free || keepShipSettings;
  const tight = fillsSpaceIn(kind);

  return sortEntries(props.items, sort.value, group.value, state.value).flatMap(
    (entry) => {
      if (ownSettings && placements.value[entry.id]?.removed) {
        return [];
      }

      const shipState =
        (ownSettings && placements.value[entry.id]?.state) || state.value;
      const shipViewpoint = drawableViewpoint(
        entry,
        (ownSettings && placements.value[entry.id]?.viewpoint) ||
          viewpoint.value,
        shipState,
      );
      const geometry = shipGeometry(entry, shipViewpoint, {
        state: shipState,
        colored: colored.value,
      });

      if (!geometry) {
        return [];
      }

      const shipFacing = ownSettings ? facingOf(entry.id) : facing.value;
      const placed = !!placements.value[entry.id];
      const shipGroup = free
        ? placed
          ? placements.value[entry.id]?.heading
          : t("labels.fleetchartApp.unplaced")
        : groupTitle(entry);

      return [
        {
          id: entry.id,
          entry,
          geometry,
          ...boxOf(geometry, shipFacing, tight),
          tight,
          state: shipState,
          facing: shipFacing,
          viewpoint: shipViewpoint,
          group: shipGroup,
          ...(shipGroup ? headingRoomFor(shipGroup) : {}),
          padding: SHIP_PADDING * SPACING_FACTORS[spacing.value],
          ...labelRoom(entry),
        },
      ];
    },
  );
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

const arrange = (
  kind: FleetchartLayouts,
  list: CanvasShip[],
  forFreeLayout = false,
) => {
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
          // Free draws a heading from a group's left edge, wherever its ships ended up.
          leftAligned: forFreeLayout && list.some((ship) => ship.group),
        },
      );
    default:
      return arrangeFree(list, placements.value, classicRowWidth.value);
  }
};

const draggedPositions = shallowRef<FleetchartPositions>();

const arranged = computed(() => arrange(layout.value, ships.value));

const positions = computed(() =>
  draggedPositions.value
    ? { ...arranged.value, ...draggedPositions.value }
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

const backgroundStyle = computed(() => {
  const image = BACKGROUND_IMAGES[options.value.background];

  return image ? { backgroundImage: `url(${image})` } : undefined;
});

const scaleBarWidth = computed(
  () => gridCell.value * PIXELS_PER_METRE * transform.value.scale,
);

const settingsOpen = ref(false);

const exporting = ref(false);

// One count for the whole chart rather than a placeholder on each ship, which on
// a fleet of thousands is more noise than the ships themselves.
const imageProgress = createImageProgress();

const exportProgress = createExportProgress();

// The images drawn while zoomed out are too small for a full-size export, so the
// larger ones are only fetched for as long as an export needs them.
const prepareExport = async () => {
  exporting.value = true;

  await nextTick();

  const images = [...(scene.value?.querySelectorAll("img") ?? [])];

  exportProgress.start(images.length);

  await Promise.race([
    Promise.all(
      images.map((image) =>
        image
          .decode()
          .catch(() => {})
          .finally(exportProgress.pictureReady),
      ),
    ),
    new Promise((resolve) => {
      setTimeout(resolve, EXPORT_IMAGE_TIMEOUT);
    }),
  ]);
};

// Shown before the capture starts, as drawing holds up the page until it is done.
const exportStage = async (stage: DownloadScreenshotStage) => {
  exportProgress.stage.value = stage;

  await new Promise((resolve) => {
    requestAnimationFrame(() => setTimeout(resolve));
  });
};

const finishExport = () => {
  exporting.value = false;
  exportProgress.finish();
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
    // A press on a ship moves that ship, and one with Shift draws a selection.
    beforeMouseDown: (event) =>
      arranging.value &&
      (event.shiftKey ||
        (event.target as Element).closest("[data-test='fleetchart-ship']"))
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

const selectedIds = ref<string[]>([]);

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
  const list = shipsFor(kind).filter(({ entry }) => !isCatalogueEntry(entry));
  const from = arrange(kind, list, true);

  return Object.fromEntries(
    list.map((ship) => [
      ship.id,
      {
        ...from[ship.id],
        facing: facing.value,
        ...(ship.group ? { heading: ship.group } : {}),
      },
    ]),
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
  [arranging, () => props.arrangeReady, () => ships.value.length],
  () => {
    if (
      arranging.value &&
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

const lastArrangement = ref(FleetchartLayouts.PACKED);

const groupAndArrange = (option: FleetchartGroups) => {
  fleetchartStore.updateOptions({
    namespace: props.namespace,
    options: { group: option },
  });

  arrangeAs(lastArrangement.value);
};

const ARRANGEMENTS = [
  FleetchartLayouts.COLUMNS,
  FleetchartLayouts.CLASSIC,
  FleetchartLayouts.PACKED,
];

// Applies a layout to what is selected, where it stands, or else to everything. Only
// the places change: each ship keeps the angle, facing and state it was given.
const arrangeAs = (kind: FleetchartLayouts) => {
  lastArrangement.value = kind;

  const selected = selectedShips.value;
  const list = shipsFor(kind, true).filter(
    ({ id }) => !selected.length || selectedIds.value.includes(id),
  );
  const from = arrange(kind, list, true);
  const current = selected.length
    ? boundsOf(selected, positions.value)
    : undefined;
  const arranged = boundsOf(list, from);
  const offsetX = current ? current.minX - arranged.minX : 0;
  const offsetY = current ? current.minY - arranged.minY : 0;

  const moved = Object.fromEntries(
    list.map(({ id, group: heading }) => {
      const { heading: _previous, ...placement } = placements.value[id] ?? {};

      return [
        id,
        {
          ...placement,
          x: from[id].x + offsetX,
          y: from[id].y + offsetY,
          ...(heading ? { heading } : {}),
        },
      ];
    }),
  );

  if (selected.length) {
    holdingView(() => {
      changePlacements({ ...placements.value, ...moved });
    });

    return;
  }

  changePlacements({ ...placements.value, ...moved });
  fitToScreen();
};

// Back to the chart as it was before anything was done to it. Ships hidden by a
// filter have no new place to go to, so they keep theirs.
const resetArrangement = () => {
  const owned = Object.entries(placements.value).flatMap(
    ([id, { removed: _removed, ...placement }]) =>
      placement.modelId ? [] : [[id, placement] as const],
  );

  changePlacements({
    ...Object.fromEntries(owned),
    ...placeAll(seedLayout),
  });
  selectedIds.value = [];
  fitToScreen();
};

const takenOff = (id: string) => ({
  ...placements.value[id],
  ...positions.value[id],
  removed: true,
});

// Empty, to build up from. Owned ships are only marked, as a ship without a placement
// would show as not placed yet.
const clearArrangement = () => {
  const owned = Object.entries(placements.value).filter(
    ([, { modelId }]) => !modelId,
  );

  changePlacements(
    Object.fromEntries(
      [
        ...owned.map(([id]) => id),
        ...ships.value
          .filter(({ entry }) => !isCatalogueEntry(entry))
          .map(({ id }) => id),
      ].map((id) => [id, takenOff(id)]),
    ),
  );
  selectedIds.value = [];
};

const selectedShips = computed(() =>
  arranging.value
    ? ships.value.filter((ship) => selectedIds.value.includes(ship.id))
    : [],
);

// Picking a ship picks everything grouped with it.
const withGroupMembers = (ids: string[]) => {
  const groupIds = new Set(
    ids.map((id) => placements.value[id]?.groupId).filter(Boolean),
  );

  return ships.value
    .filter(
      ({ id }) =>
        ids.includes(id) || groupIds.has(placements.value[id]?.groupId),
    )
    .map(({ id }) => id);
};

// What all the selected ships share, for the controls to show as current.
const sharedValue = <T,>(values: T[]) =>
  values.every((value) => value === values[0]) ? values[0] : undefined;

const selectedViewpoint = computed(() =>
  sharedValue(selectedShips.value.map((ship) => ship.viewpoint)),
);

const selectedFacing = computed(() =>
  sharedValue(selectedShips.value.map((ship) => ship.facing)),
);

const hasView = (ship: CanvasShip, option: FleetchartViewpoints) =>
  !!viewFor(ship.entry, option, {
    state: ship.state,
    colored: colored.value,
  });

// An angle with no picture would leave a ship blank, so one is offered as long as
// a selected ship has it, and given only to those that do.
const selectedShipViewpoints = computed(() =>
  Object.values(FleetchartViewpoints).filter((option) =>
    selectedShips.value.some((ship) => hasView(ship, option)),
  ),
);

const changeShips = (
  list: CanvasShip[],
  changes: (ship: CanvasShip) => Partial<FleetchartPlacement>,
) => {
  if (!list.length) {
    return;
  }

  const updated = Object.fromEntries(
    list.flatMap((ship) => {
      const current = positions.value[ship.id];

      return current
        ? [
            [
              ship.id,
              {
                ...placements.value[ship.id],
                x: current.x,
                y: current.y,
                ...changes(ship),
              },
            ],
          ]
        : [];
    }),
  );

  holdingView(() => {
    changePlacements({ ...placements.value, ...updated });
  });
};

const setSelectedViewpoint = (option: FleetchartViewpoints) => {
  changeShips(
    selectedShips.value.filter((ship) => hasView(ship, option)),
    () => ({ viewpoint: option }),
  );
};

const selectedState = computed(() =>
  sharedValue(selectedShips.value.map((ship) => ship.state)),
);

const selectedShipStates = computed(() =>
  Object.values(FleetchartShipStates).filter((option) =>
    selectedShips.value.some((ship) => hasStateViews(ship.entry, option)),
  ),
);

const setSelectedState = (option: FleetchartShipStates) => {
  changeShips(
    selectedShips.value.filter((ship) => hasStateViews(ship.entry, option)),
    () => ({ state: option }),
  );
};

const setSelectedFacing = (option: FleetchartFacings) => {
  changeShips(selectedShips.value, () => ({ facing: option }));
};

const rotateSelected = () => {
  changeShips(selectedShips.value, (ship) => ({
    facing:
      FACING_CYCLE[
        (FACING_CYCLE.indexOf(ship.facing) + 1) % FACING_CYCLE.length
      ],
  }));
};

const orderOf = (id: string) => placements.value[id]?.order ?? 0;

// Keeps the selected ships' order among themselves.
const stackSelected = (direction: "front" | "back") => {
  const orders = Object.keys(placements.value).map(orderOf);
  const sorted = [...selectedShips.value].sort(
    (a, b) => orderOf(a.id) - orderOf(b.id),
  );
  const start =
    direction === "front"
      ? Math.max(0, ...orders) + 1
      : Math.min(0, ...orders) - sorted.length;

  changeShips(sorted, (ship) => ({ order: start + sorted.indexOf(ship) }));
};

const savedLayoutsOpen = ref(false);

// The panels share one spot, so only one can be open.
const togglePanel = (open: boolean, panel: "saved" | "settings") => {
  savedLayoutsOpen.value = panel === "saved" && !open;
  settingsOpen.value = panel === "settings" && !open;
};

const metresAtX = (pixels: number) =>
  (pixels - transform.value.x) / transform.value.scale / PIXELS_PER_METRE -
  SCENE_PADDING / PIXELS_PER_METRE +
  bounds.value.minX;

const metresAtY = (pixels: number) =>
  (pixels - transform.value.y) / transform.value.scale / PIXELS_PER_METRE -
  SCENE_PADDING / PIXELS_PER_METRE +
  bounds.value.minY;

let shipsAdded = 0;

// A catalogue ship is drawn once its model and pictures have arrived, and only then
// can it grow the scene. So the view is held, or the chart fitted, at that moment.
const arriving = new Set<string>();

let fitOnArrival = false;

watch([() => ships.value.length, bounds], ([, now], [, before]) => {
  const arrived = ships.value.filter(({ id }) => arriving.has(id));

  if (!arrived.length) {
    return;
  }

  arrived.forEach(({ id }) => arriving.delete(id));

  if (fitOnArrival) {
    fitOnArrival = arriving.size > 0;
    fitToScreen();

    return;
  }

  if (panzoomInstance) {
    const { x, y, scale } = panzoomInstance.getTransform();

    panzoomInstance.moveTo(
      x + (now.minX - before.minX) * PIXELS_PER_METRE * scale,
      y + (now.minY - before.minY) * PIXELS_PER_METRE * scale,
    );
  }
});

// In the middle of what is on screen and in front of everything else, selected so
// that they can be moved straight away. One step to undo, however many there are.
const addShips = (selection: ModelPickerSelection[]) => {
  const centreX = metresAtX(screen.width / 2);
  const centreY = metresAtY(screen.height / 2);
  let order = Math.max(0, ...Object.keys(placements.value).map(orderOf));

  const added = selection.flatMap(({ option, quantity }) =>
    Array.from({ length: quantity }, () => {
      const offset = (shipsAdded % ADDED_SHIP_OFFSETS) * ADDED_SHIP_OFFSET;

      shipsAdded += 1;
      order += 1;

      return [
        crypto.randomUUID(),
        {
          x: centreX + offset,
          y: centreY + offset,
          facing: facing.value,
          order,
          modelId: option.id,
        },
      ] as const;
    }),
  );

  fitOnArrival = false;
  added.forEach(([id]) => arriving.add(id));

  changePlacements({ ...placements.value, ...Object.fromEntries(added) });

  selectedIds.value = added.map(([id]) => id);
};

const openAddShips = () => {
  comlink.emit("open-modal", {
    component: () => import("./AddShipsModal/index.vue"),
    props: { add: addShips },
    wide: true,
  });
};

// A ship from the catalogue goes altogether; an owned one is only taken off the chart.
const removeSelectedShips = () => {
  const selected = selectedShips.value;
  const remaining = Object.fromEntries(
    Object.entries(placements.value).filter(
      ([id]) => !selected.some((ship) => ship.id === id),
    ),
  );
  const owned = selected.filter(({ entry }) => !isCatalogueEntry(entry));

  holdingView(() => {
    changePlacements({
      ...remaining,
      ...Object.fromEntries(owned.map(({ id }) => [id, takenOff(id)])),
    });
  });

  selectedIds.value = [];
};

// A saved layout has to look the same without this chart's own view and state, so
// each ship carries what it is actually drawn with.
const allPlacementsToSave = computed(() => {
  const drawn = ships.value.map(({ id }) => id);
  const notDrawn = Object.keys(placements.value).filter(
    (id) => !drawn.includes(id),
  );
  const orders = stackingOrders([...notDrawn, ...drawn], orderOf);

  return Object.entries(placements.value).map(([id, placement]) => {
    const ship = ships.value.find((drawnShip) => drawnShip.id === id);

    return {
      id,
      modelId: placement.modelId,
      x: placement.x,
      y: placement.y,
      facing: ship?.facing ?? placement.facing,
      viewpoint: ship?.viewpoint ?? placement.viewpoint,
      state: ship?.state ?? placement.state,
      order: orders[id],
      groupId: placement.groupId,
      heading: placement.heading,
      removed: placement.removed,
    };
  });
});

const placementsToSave = computed<FleetchartPlacementInput[]>(() =>
  allPlacementsToSave.value.flatMap(({ id, modelId, ...placement }) =>
    modelId ? [] : [{ vehicleId: id, ...placement }],
  ),
);

const cataloguePlacementsToSave = computed<FleetchartCataloguePlacement[]>(() =>
  allPlacementsToSave.value.flatMap(
    ({ id, modelId, removed: _removed, ...placement }) =>
      modelId ? [{ id, modelId, ...placement }] : [],
  ),
);

const openSavedLayout = (saved: FleetchartLayout) => {
  changePlacements(
    placementsFromLayout(saved.placements, saved.cataloguePlacements),
  );

  arriving.clear();
  (saved.cataloguePlacements ?? []).forEach(({ id }) => arriving.add(id));
  fitOnArrival = arriving.size > 0;

  if (saved.colored !== colored.value) {
    fleetchartStore.togglePlain(props.namespace);
  }

  fleetchartStore.updateOptions({
    namespace: props.namespace,
    options: { background: saved.background as FleetchartBackgrounds },
  });

  selectedIds.value = [];
  fitToScreen();
};

const canGroupSelected = computed(
  () =>
    selectedShips.value.length > 1 &&
    (!sharedValue(
      selectedShips.value.map((ship) => placements.value[ship.id]?.groupId),
    ) as boolean),
);

const canUngroupSelected = computed(() =>
  selectedShips.value.some((ship) => placements.value[ship.id]?.groupId),
);

const groupSelected = () => {
  const groupId = crypto.randomUUID();

  changeShips(selectedShips.value, () => ({ groupId }));
};

const ungroupSelected = () => {
  changeShips(selectedShips.value, () => ({ groupId: undefined }));
};

const shipControls = ref<{ $el: HTMLElement }>();

const shipControlsHalfWidth = ref(0);

// Measured, as its width depends on the labels and the language.
watch(
  [
    selectedViewpoint,
    selectedFacing,
    selectedState,
    () => selectedShips.value.length,
  ],
  async () => {
    await nextTick();

    shipControlsHalfWidth.value =
      (shipControls.value?.$el.offsetWidth ?? 0) / 2;
  },
);

// Drawn over the scene rather than in it, so it stays readable at any zoom and
// never reaches an export.
const shipControlsStyle = computed(() => {
  const placed = selectedShips.value.filter((ship) => positions.value[ship.id]);

  if (!placed.length) {
    return undefined;
  }

  const covered = boundsOf(placed, positions.value);
  const { x, y, scale } = transform.value;
  const top = y + sceneY(covered.minY) * scale;
  const bottom = y + sceneY(covered.minY + covered.height) * scale;
  const above = top > SHIP_CONTROLS_MIN_TOP;
  const centre = x + sceneX(covered.minX + covered.width / 2) * scale;

  return {
    left: `${Math.min(
      Math.max(centre, shipControlsHalfWidth.value + SHIP_CONTROLS_MARGIN),
      screen.width - shipControlsHalfWidth.value - SHIP_CONTROLS_MARGIN,
    )}px`,
    top: `${above ? top - SHIP_CONTROLS_GAP : bottom + SHIP_CONTROLS_GAP}px`,
    transform: `translate(-50%, ${above ? "-100%" : "0"})`,
  };
});

const marquee = shallowRef<{
  left: number;
  top: number;
  width: number;
  height: number;
}>();

let stopMarquee: (() => void) | undefined;

const startMarquee = (event: PointerEvent) => {
  const origin = (event.currentTarget as HTMLElement).getBoundingClientRect();
  const startX = event.clientX - origin.left;
  const startY = event.clientY - origin.top;
  const additions = [...selectedIds.value];

  const onMove = (move: PointerEvent) => {
    const x = move.clientX - origin.left;
    const y = move.clientY - origin.top;

    marquee.value = {
      left: Math.min(startX, x),
      top: Math.min(startY, y),
      width: Math.abs(x - startX),
      height: Math.abs(y - startY),
    };
  };

  const onCancel = () => {
    stopMarquee?.();
    marquee.value = undefined;
  };

  const onUp = () => {
    stopMarquee?.();

    const box = marquee.value;

    marquee.value = undefined;

    if (!box) {
      return;
    }

    const left = metresAtX(box.left);
    const right = metresAtX(box.left + box.width);
    const top = metresAtY(box.top);
    const bottom = metresAtY(box.top + box.height);

    const inside = ships.value
      .filter((ship) => {
        const position = positions.value[ship.id];

        return (
          position &&
          position.x + ship.width / 2 > left &&
          position.x - ship.width / 2 < right &&
          position.y + ship.height / 2 > top &&
          position.y - ship.height / 2 < bottom
        );
      })
      .map((ship) => ship.id);

    selectedIds.value = withGroupMembers([...additions, ...inside]);
  };

  stopMarquee = () => {
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
    window.removeEventListener("pointercancel", onCancel);
    stopMarquee = undefined;
  };

  window.addEventListener("pointermove", onMove);
  window.addEventListener("pointerup", onUp);
  window.addEventListener("pointercancel", onCancel);
};

const handleViewportPress = (event: PointerEvent) => {
  if ((event.target as Element).closest("[data-test='fleetchart-ship']")) {
    return;
  }

  if (arranging.value && event.shiftKey && event.button === 0) {
    event.preventDefault();
    startMarquee(event);
  } else {
    selectedIds.value = [];
  }
};

let stopDrag: (() => void) | undefined;

const selectForPress = (id: string, additive: boolean) => {
  const picked = withGroupMembers([id]);

  if (!additive) {
    if (!selectedIds.value.includes(id)) {
      selectedIds.value = picked;
    }

    return;
  }

  selectedIds.value = selectedIds.value.includes(id)
    ? selectedIds.value.filter((selected) => !picked.includes(selected))
    : [...selectedIds.value, ...picked];
};

const startDrag = (id: string, event: PointerEvent) => {
  if (!arranging.value || event.pointerType === "touch" || event.button !== 0) {
    return;
  }

  event.preventDefault();

  selectForPress(id, event.shiftKey || event.metaKey || event.ctrlKey);

  if (!selectedIds.value.includes(id)) {
    return;
  }

  const moving = selectedShips.value;
  const lead = moving.find((ship) => ship.id === id);

  if (!lead) {
    return;
  }

  const starts = Object.fromEntries(
    moving.map((ship) => [ship.id, positions.value[ship.id]]),
  );

  stopDrag?.();

  // Keeps the drag alive when the pointer leaves the window.
  (event.target as Element).setPointerCapture?.(event.pointerId);

  const { clientX, clientY } = event;
  const additive = event.shiftKey || event.metaKey || event.ctrlKey;

  const onMove = (move: PointerEvent) => {
    const metresPerPixel = 1 / (PIXELS_PER_METRE * transform.value.scale);
    const moved = {
      x: starts[id].x + (move.clientX - clientX) * metresPerPixel,
      y: starts[id].y + (move.clientY - clientY) * metresPerPixel,
    };
    // The grid applies to the ship being held; the rest keep their distance to it.
    const landed = gridEnabled.value
      ? snapToGrid(moved, lead, gridCell.value)
      : moved;
    const deltaX = landed.x - starts[id].x;
    const deltaY = landed.y - starts[id].y;

    holdingView(() => {
      draggedPositions.value = Object.fromEntries(
        moving.map((ship) => [
          ship.id,
          {
            x: starts[ship.id].x + deltaX,
            y: starts[ship.id].y + deltaY,
          },
        ]),
      );
    });
  };

  const onUp = () => {
    const dropped = draggedPositions.value;

    stopDrag?.();

    // A press without a move on one of several selected ships means just that ship.
    if (!dropped && !additive) {
      selectedIds.value = withGroupMembers([id]);
    }

    if (dropped) {
      holdingView(() => {
        draggedPositions.value = undefined;
        changePlacements({
          ...placements.value,
          ...Object.fromEntries(
            Object.entries(dropped as FleetchartPositions).map(
              ([shipId, { x, y }]) => [
                shipId,
                {
                  ...placements.value[shipId],
                  x,
                  y,
                  facing: facingOf(shipId),
                },
              ],
            ),
          ),
        });
      });
    }
  };

  const onCancel = () => {
    stopDrag?.();
    holdingView(() => {
      draggedPositions.value = undefined;
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

// A modal opened over the chart keeps its keys to itself.
const isEditable = (target: EventTarget | null) =>
  target instanceof HTMLElement &&
  (target.isContentEditable ||
    ["INPUT", "SELECT", "TEXTAREA"].includes(target.tagName) ||
    !!target.closest(".app-modal"));

const handleArrangeKeys = (event: KeyboardEvent) => {
  if (!arranging.value || isEditable(event.target)) {
    return;
  }

  if ((event.metaKey || event.ctrlKey) && event.key === "z") {
    event.preventDefault();
    undo();
  } else if (event.key === "Escape") {
    selectedIds.value = [];
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
  stopMarquee?.();
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
  fleetchartStore.togglePlain(props.namespace);
};

const toggleLabels = () => {
  fleetchartStore.toggleLabels(props.namespace);
};
</script>

<template>
  <div class="fleetchart-wrapper" data-test="fleetchart-canvas">
    <div class="fleetchart-controls">
      <template v-if="arranging">
        <BtnDropdown data-test="fleetchart-arrange">
          <template #label>
            {{
              selectedShips.length
                ? t("labels.fleetchartApp.arrangeSelected", {
                    count: selectedShips.length,
                  })
                : t("labels.fleetchartApp.arrange")
            }}
          </template>
          <Btn
            v-for="option in ARRANGEMENTS"
            :key="option"
            :data-test="`fleetchart-arrange-${option}`"
            variant="bare"
            @click="arrangeAs(option)"
          >
            {{ t(`labels.fleetchartApp.layoutOptions.${option}`) }}
          </Btn>
          <hr />
          <Btn
            v-for="option in groups"
            :key="option"
            :active="group === option"
            :data-test="`fleetchart-arrange-group-${option}`"
            variant="bare"
            @click="groupAndArrange(option)"
          >
            {{
              t("labels.fleetchartApp.groupBy", {
                group: t(`labels.fleetchartApp.groupOptions.${option}`),
              })
            }}
          </Btn>
        </BtnDropdown>
        <Btn
          v-tooltip="t('labels.fleetchartApp.addShips')"
          :aria-label="t('labels.fleetchartApp.addShips')"
          :disabled="!arrangeReady"
          data-test="fleetchart-add-ships"
          @click="openAddShips"
        >
          <i class="fa-solid fa-plus" />
        </Btn>
        <Btn
          v-tooltip="t('labels.fleetchartApp.savedLayouts')"
          :active="savedLayoutsOpen"
          :aria-label="t('labels.fleetchartApp.savedLayouts')"
          data-test="fleetchart-saved-layouts"
          @click="togglePanel(savedLayoutsOpen, 'saved')"
        >
          <i class="fa-duotone fa-bookmark" />
        </Btn>
        <Btn
          v-tooltip="t('labels.fleetchartApp.undo')"
          :aria-label="t('labels.fleetchartApp.undo')"
          :disabled="!undoStack.length"
          data-test="fleetchart-undo"
          @click="undo"
        >
          <i class="fa-duotone fa-rotate-left" />
        </Btn>
        <BtnConfirm
          v-tooltip="t('labels.fleetchartApp.clearArrangement')"
          :aria-label="t('labels.fleetchartApp.clearArrangement')"
          :disabled="!arrangeReady"
          hide-question
          data-test="fleetchart-clear-arrangement"
          @confirm="clearArrangement"
        >
          <i class="fa-duotone fa-eraser" />
        </BtnConfirm>
        <BtnConfirm
          v-tooltip="t('labels.fleetchartApp.resetArrangement')"
          :aria-label="t('labels.fleetchartApp.resetArrangement')"
          :disabled="!arrangeReady"
          hide-question
          data-test="fleetchart-reset-arrangement"
          @confirm="resetArrangement"
        >
          <i class="fa-duotone fa-arrows-rotate" />
        </BtnConfirm>
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

      <BtnDropdown v-if="!readOnly">
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
        v-if="!readOnly"
        :active="settingsOpen"
        :aria-label="t('labels.fleetchartApp.options')"
        data-test="fleetchart-options"
        @click="togglePanel(settingsOpen, 'settings')"
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
            :stage="exportStage"
            :finish="finishExport"
          />

          <hr />
        </template>

        <Btn v-if="!readOnly" @click="toggleLabels">
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
      :options="options"
      :groups="groups"
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

    <FleetchartCanvasProgress
      :images="imageProgress"
      :export-progress="exportProgress"
    />

    <div v-if="gridEnabled" class="fleetchart-canvas__grid-label">
      {{ t("labels.fleetchartApp.gridSize", { size: gridCell }) }}
    </div>

    <FleetchartCanvasSavedLayouts
      v-if="arranging && savedLayoutsOpen"
      :placements="placementsToSave"
      :catalogue-placements="cataloguePlacementsToSave"
      :ready="arrangeReady && allPlacementsToSave.length > 0"
      :colored="colored"
      :background="options.background"
      @open="openSavedLayout"
    />

    <FleetchartCanvasShipControls
      ref="shipControls"
      v-if="selectedShips.length && !draggedPositions && !exporting"
      :count="selectedShips.length"
      :viewpoint="selectedViewpoint"
      :available="selectedShipViewpoints"
      :facing="selectedFacing"
      :state="selectedState"
      :available-states="selectedShipStates"
      :can-group="canGroupSelected"
      :can-ungroup="canUngroupSelected"
      :style="shipControlsStyle"
      @update:viewpoint="setSelectedViewpoint"
      @update:facing="setSelectedFacing"
      @update:state="setSelectedState"
      @stack="stackSelected"
      @group="groupSelected"
      @ungroup="ungroupSelected"
      @remove="removeSelectedShips"
    />

    <div class="fleetchart-canvas__viewport" @pointerdown="handleViewportPress">
      <div
        v-if="backgroundStyle"
        class="fleetchart-canvas__background"
        :style="backgroundStyle"
        data-test="fleetchart-background"
      />

      <div
        v-if="marquee"
        class="fleetchart-canvas__marquee"
        :style="{
          left: `${marquee.left}px`,
          top: `${marquee.top}px`,
          width: `${marquee.width}px`,
          height: `${marquee.height}px`,
        }"
        data-test="fleetchart-marquee"
      />

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
          v-if="backgroundStyle"
          class="fleetchart-canvas__export-only fleetchart-canvas__background fleetchart-canvas__export-background"
          :style="backgroundStyle"
        />

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
            fontSize: `${headingFontSize}px`,
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
          :state="ship.state"
          :tight="ship.tight"
          :box-width="ship.width"
          :box-height="ship.height"
          :facing="ship.facing"
          :selected="isFree && !exporting && selectedIds.includes(ship.id)"
          :arranging="arranging"
          :order="isFree ? placements[ship.id]?.order : undefined"
          :shadow="ships.length <= MAX_SHADOWED_SHIPS"
          @pointerdown="startDrag(ship.id, $event)"
          @image-pending="imageProgress.pending(ship.id)"
          @image-settled="imageProgress.settled(ship.id)"
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
