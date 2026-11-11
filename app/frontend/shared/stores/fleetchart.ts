import { defineStore } from "pinia";
import { type Transform } from "panzoom";

export enum FleetchartViewpoints {
  TOP = "top",
  PORT = "port",
  ANGLED = "angled",
  FRONT = "front",
  STARBOARD = "starboard",
  BOTTOM = "bottom",
  ANGLED_REAR = "angledRear",
  REAR = "rear",
}

// What the charts behind the flag know how to draw.
export const LEGACY_FLEETCHART_VIEWPOINTS = [
  FleetchartViewpoints.TOP,
  FleetchartViewpoints.PORT,
  FleetchartViewpoints.ANGLED,
  FleetchartViewpoints.FRONT,
];

export enum FleetchartScreenHeights {
  AUTO = "auto",
  ONE = "1x",
  ONEFIVE = "1_5x",
  TWO = "2x",
  THREE = "3x",
  FOUR = "4x",
}

export enum FleetchartModes {
  PANZOOM = "panzoom",
  CLASSIC = "classic",
}

export enum FleetchartLayouts {
  COLUMNS = "columns",
  CLASSIC = "classic",
  PACKED = "packed",
  FREE = "free",
}

export enum FleetchartSorts {
  LENGTH_ASC = "lengthAsc",
  LENGTH_DESC = "lengthDesc",
  NAME = "name",
  LIST = "list",
}

export enum FleetchartGroups {
  NONE = "none",
  MANUFACTURER = "manufacturer",
  CLASSIFICATION = "classification",
  STATUS = "status",
  SQUADRON = "squadron",
  CAPTAIN = "captain",
  HANGAR_GROUP = "hangarGroup",
}

// Only a fleet's own ships know who flies them and in which squadron.
export const FLEET_SHIP_GROUPS = [
  FleetchartGroups.SQUADRON,
  FleetchartGroups.CAPTAIN,
];

// Only a hangar's own ships carry the groups their owner sorted them into.
export const HANGAR_SHIP_GROUPS = [FleetchartGroups.HANGAR_GROUP];

export enum FleetchartHeadingSizes {
  FLEET = "fleet",
  NORMAL = "normal",
  LARGE = "large",
  EXTRA_LARGE = "extraLarge",
}

export enum FleetchartSpacings {
  COMPACT = "compact",
  NORMAL = "normal",
  WIDE = "wide",
}

export enum FleetchartFacings {
  LEFT = "left",
  TOP = "top",
  RIGHT = "right",
  BOTTOM = "bottom",
}

export enum FleetchartShipStates {
  FLIGHT = "flight",
  EXTENDED = "extended",
  LANDED = "landed",
}

export enum FleetchartBackgrounds {
  DARK = "dark",
  STANTON = "stanton",
  CRUSADER = "crusader",
  PYRO = "pyro",
}

export interface FleetchartOptions {
  sort: FleetchartSorts;
  group: FleetchartGroups;
  headingSize: FleetchartHeadingSizes;
  spacing: FleetchartSpacings;
  scaleBar: boolean;
  solidExport: boolean;
  facing: FleetchartFacings;
  state: FleetchartShipStates;
  background: FleetchartBackgrounds;
}

export const DEFAULT_FLEETCHART_OPTIONS: FleetchartOptions = {
  sort: FleetchartSorts.LENGTH_ASC,
  group: FleetchartGroups.NONE,
  headingSize: FleetchartHeadingSizes.FLEET,
  spacing: FleetchartSpacings.NORMAL,
  scaleBar: false,
  solidExport: false,
  facing: FleetchartFacings.LEFT,
  state: FleetchartShipStates.FLIGHT,
  background: FleetchartBackgrounds.DARK,
};

export interface FleetchartPlacement {
  x: number;
  y: number;
  facing?: FleetchartFacings;
  viewpoint?: FleetchartViewpoints;
  state?: FleetchartShipStates;
  // Stacking order among ships placed on top of each other.
  order?: number;
  // Ships sharing one are selected and moved together.
  groupId?: string;
  // The title of the group an arrangement put this ship in, as a layout shows it.
  heading?: string;
  // Set on a ship from the catalogue, which is placed without being owned.
  modelId?: string;
  // Taken off the chart; without this it would come back as not placed yet.
  removed?: boolean;
}

export type FleetchartPlacements = Record<string, FleetchartPlacement>;

type FleetchartState = {
  placements: {
    [key: string]: FleetchartPlacements;
  };
  options: {
    [key: string]: Partial<FleetchartOptions>;
  };
  layout: {
    [key: string]: FleetchartLayouts;
  };
  visible: string[];
  zoomData: {
    [key: string]: Transform;
  };
  viewpoint: {
    [key: string]: FleetchartViewpoints;
  };
  labelsVisible: string[];
  screenHeight: {
    [key: string]: FleetchartScreenHeights;
  };
  mode: {
    [key: string]: FleetchartModes;
  };
  scale: {
    [key: string]: number;
  };
  color: string[];
  plain: string[];
  extended: string[];
  modelGrouped: string[];
};

export const useFleetchartStore = defineStore("fleetchart", {
  state: (): FleetchartState => ({
    placements: {},
    options: {},
    layout: {},
    visible: [],
    zoomData: {},
    viewpoint: {},
    labelsVisible: [],
    screenHeight: {},
    mode: {},
    scale: {},
    color: [],
    plain: [],
    extended: [],
    modelGrouped: [],
  }),
  getters: {
    isVisible: (state) => {
      return (namespace: string) => state.visible.includes(namespace);
    },
    showLabels: (state) => {
      return (namespace: string) => state.labelsVisible.includes(namespace);
    },
    colored: (state) => {
      return (namespace: string) => state.color.includes(namespace);
    },
    // Colored unless somebody chose otherwise, which `colored` does not assume.
    coloredByDefault: (state) => {
      return (namespace: string) => !(state.plain || []).includes(namespace);
    },
    extendedState: (state) => {
      return (namespace: string) => (state.extended || []).includes(namespace);
    },
    groupedByModel: (state) => {
      return (namespace: string) =>
        (state.modelGrouped || []).includes(namespace);
    },
    fleetchartMode: (state) => {
      return (namespace: string) => state.mode[namespace] || "panzoom";
    },
    // Somebody who chose a mode keeps its arrangement. `layout` can also be missing
    // altogether from state persisted before it existed.
    fleetchartLayout: (state) => {
      return (namespace: string, canArrange = true) => {
        const layout = state.layout?.[namespace];

        // The hangar's namespace is shared with lists that have nothing to arrange.
        if (layout === FleetchartLayouts.FREE && !canArrange) {
          return FleetchartLayouts.PACKED;
        }

        if (layout) {
          return layout;
        }

        switch (state.mode[namespace]) {
          case FleetchartModes.CLASSIC:
            return FleetchartLayouts.CLASSIC;
          case FleetchartModes.PANZOOM:
            return FleetchartLayouts.COLUMNS;
          default:
            return FleetchartLayouts.PACKED;
        }
      };
    },
    fleetchartPlacements: (state) => {
      return (namespace: string): FleetchartPlacements =>
        state.placements?.[namespace] ?? {};
    },
    fleetchartOptions: (state) => {
      return (namespace: string): FleetchartOptions => ({
        ...DEFAULT_FLEETCHART_OPTIONS,
        // Somebody who had turned on the extended toggle keeps seeing that.
        ...((state.extended || []).includes(namespace)
          ? { state: FleetchartShipStates.EXTENDED }
          : {}),
        ...state.options?.[namespace],
      });
    },
    fleetchartScreenHeight: (state) => {
      return (namespace: string) =>
        state.screenHeight[namespace] || FleetchartScreenHeights.AUTO;
    },
    fleetchartScale: (state) => {
      return (namespace: string) => state.scale[namespace] || 1;
    },
    fleetchartViewpoint: (state) => {
      return (namespace: string) => {
        const viewpoint = state.viewpoint[namespace];

        // The port viewpoint was persisted as "side" before it was renamed.
        if (!viewpoint || (viewpoint as string) === "side") {
          return FleetchartViewpoints.PORT;
        }

        return viewpoint;
      };
    },
    fleetchartZoomData: (state) => {
      return (namespace: string) => state.zoomData[namespace] || {};
    },
  },
  actions: {
    show(namespace: string) {
      if (!this.visible.includes(namespace)) {
        this.visible.push(namespace);
      }
    },
    hide(namespace: string) {
      if (this.visible.includes(namespace)) {
        this.visible = this.visible.filter((item) => item !== namespace);
      }
    },
    toggleFleetchart(namespace: string) {
      if (this.visible.includes(namespace)) {
        this.visible = this.visible.filter((item) => item !== namespace);
      } else {
        this.visible.push(namespace);
      }
    },
    toggleColored(namespace: string) {
      if (this.color.includes(namespace)) {
        this.color = this.color.filter((item) => item !== namespace);
      } else {
        this.color.push(namespace);
      }
    },
    togglePlain(namespace: string) {
      const current = this.plain || [];

      this.plain = current.includes(namespace)
        ? current.filter((item) => item !== namespace)
        : [...current, namespace];
    },
    toggleExtended(namespace: string) {
      const current = this.extended || [];
      if (current.includes(namespace)) {
        this.extended = current.filter((item) => item !== namespace);
      } else {
        this.extended = [...current, namespace];
      }
    },
    toggleGroupedByModel(namespace: string) {
      const current = this.modelGrouped || [];

      this.modelGrouped = current.includes(namespace)
        ? current.filter((item) => item !== namespace)
        : [...current, namespace];
    },
    toggleLabels(namespace: string) {
      if (this.labelsVisible.includes(namespace)) {
        this.labelsVisible = this.labelsVisible.filter(
          (item) => item !== namespace,
        );
      } else {
        this.labelsVisible.push(namespace);
      }
    },
    updateViewpoint(payload: {
      namespace: string;
      viewpoint: FleetchartViewpoints;
    }) {
      this.viewpoint[payload.namespace] = payload.viewpoint;
    },
    updateMode(payload: { namespace: string; mode: FleetchartModes }) {
      this.mode[payload.namespace] = payload.mode;
    },
    updateLayout(payload: { namespace: string; layout: FleetchartLayouts }) {
      this.layout = { ...this.layout, [payload.namespace]: payload.layout };
    },
    updatePlacements(payload: {
      namespace: string;
      placements: FleetchartPlacements;
    }) {
      this.placements = {
        ...this.placements,
        [payload.namespace]: payload.placements,
      };
    },
    updateOptions(payload: {
      namespace: string;
      options: Partial<FleetchartOptions>;
    }) {
      this.options = {
        ...this.options,
        [payload.namespace]: {
          ...this.options?.[payload.namespace],
          ...payload.options,
        },
      };
    },
    updateScale(payload: { namespace: string; scale: number }) {
      this.scale[payload.namespace] = payload.scale;
    },
    updateScreenHeight(payload: {
      namespace: string;
      screenHeight: FleetchartScreenHeights;
    }) {
      this.screenHeight[payload.namespace] = payload.screenHeight;
    },
    updateZoomData(payload: { namespace: string; zoomData: Transform }) {
      this.zoomData[payload.namespace] = payload.zoomData;
    },
  },
  persist: true,
});
