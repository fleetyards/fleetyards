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
import {
  groupTitleOf,
  sortEntries,
} from "@/frontend/components/Fleetchart/options";
import {
  placementsFromLayout,
  stackingOrders,
  type FleetchartPlacementInput,
} from "@/frontend/components/Fleetchart/savedLayouts";
import type { FleetchartLayout } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
import {
  FleetchartFacings,
  FleetchartGroups,
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
}

const props = withDefaults(defineProps<Props>(), {
  items: () => [],
  downloadName: undefined,
  canArrange: false,
  readOnly: false,
  arrangeReady: true,
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

const colored = computed(() =>
  fleetchartStore.coloredByDefault(props.namespace),
);

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

const groupTitle = (entry: FleetchartEntry) => {
  if (group.value === FleetchartGroups.NONE) {
    return undefined;
  }

  return (
    groupTitleOf(entry, group.value, t) ||
    t("labels.fleetchartApp.groupOptions.none")
  );
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
          ? undefined
          : t("labels.fleetchartApp.unplaced")
        : keepShipSettings
          ? undefined
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
          headingWidth: shipGroup
            ? labelMeasure.value.width(shipGroup) / PIXELS_PER_METRE
            : 0,
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

const ARRANGEMENTS = [
  FleetchartLayouts.COLUMNS,
  FleetchartLayouts.CLASSIC,
  FleetchartLayouts.PACKED,
];

// Applies a layout to what is selected, where it stands, or else to everything. Only
// the places change: each ship keeps the angle, facing and state it was given.
const arrangeAs = (kind: FleetchartLayouts) => {
  const selected = selectedShips.value;
  const list = shipsFor(kind, true).filter(
    ({ id }) => !selected.length || selectedIds.value.includes(id),
  );
  const from = arrange(kind, list);
  const current = selected.length
    ? boundsOf(selected, positions.value)
    : undefined;
  const arranged = boundsOf(list, from);
  const offsetX = current ? current.minX - arranged.minX : 0;
  const offsetY = current ? current.minY - arranged.minY : 0;

  const moved = Object.fromEntries(
    list.map(({ id }) => [
      id,
      {
        ...placements.value[id],
        x: from[id].x + offsetX,
        y: from[id].y + offsetY,
      },
    ]),
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

const resetArrangement = () => {
  // Merged, as ships hidden by a filter keep their place.
  changePlacements({ ...placements.value, ...placeAll(seedLayout) });
  fitToScreen();
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

// A saved layout has to look the same without this chart's own view and state, so
// each ship carries what it is actually drawn with.
const placementsToSave = computed<FleetchartPlacementInput[]>(() => {
  const drawn = ships.value.map(({ id }) => id);
  const notDrawn = Object.keys(placements.value).filter(
    (id) => !drawn.includes(id),
  );
  const orders = stackingOrders([...notDrawn, ...drawn], orderOf);

  return Object.entries(placements.value).map(([vehicleId, placement]) => {
    const ship = ships.value.find(({ id }) => id === vehicleId);

    return {
      vehicleId,
      x: placement.x,
      y: placement.y,
      facing: ship?.facing ?? placement.facing,
      viewpoint: ship?.viewpoint ?? placement.viewpoint,
      state: ship?.state ?? placement.state,
      order: orders[vehicleId],
      groupId: placement.groupId,
    };
  });
});

const openSavedLayout = (saved: FleetchartLayout) => {
  changePlacements(placementsFromLayout(saved.placements));

  if (saved.colored !== colored.value) {
    fleetchartStore.togglePlain(props.namespace);
  }

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

  const metresX = (pixels: number) =>
    (pixels - transform.value.x) / transform.value.scale / PIXELS_PER_METRE -
    SCENE_PADDING / PIXELS_PER_METRE +
    bounds.value.minX;
  const metresY = (pixels: number) =>
    (pixels - transform.value.y) / transform.value.scale / PIXELS_PER_METRE -
    SCENE_PADDING / PIXELS_PER_METRE +
    bounds.value.minY;

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

    const left = metresX(box.left);
    const right = metresX(box.left + box.width);
    const top = metresY(box.top);
    const bottom = metresY(box.top + box.height);

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

const isEditable = (target: EventTarget | null) =>
  target instanceof HTMLElement &&
  (target.isContentEditable ||
    ["INPUT", "SELECT", "TEXTAREA"].includes(target.tagName));

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
        </BtnDropdown>
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

    <FleetchartCanvasSavedLayouts
      v-if="arranging && savedLayoutsOpen"
      :placements="placementsToSave"
      :ready="arrangeReady && placementsToSave.length > 0"
      :colored="colored"
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
    />

    <div class="fleetchart-canvas__viewport" @pointerdown="handleViewportPress">
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
          :state="ship.state"
          :tight="ship.tight"
          :box-width="ship.width"
          :box-height="ship.height"
          :facing="ship.facing"
          :selected="isFree && !exporting && selectedIds.includes(ship.id)"
          :arranging="arranging"
          :order="isFree ? placements[ship.id]?.order : undefined"
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
