import { defineStore } from "pinia";
import { type Transform } from "panzoom";

export enum FleetchartViewpoints {
  TOP = "top",
  SIDE = "side",
  ANGLED = "angled",
  FRONT = "front",
}

export enum FleetchartScreenHeights {
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

type FleetchartState = {
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
};

export const useFleetchartStore = defineStore("fleetchart", {
  state: (): FleetchartState => ({
    visible: [],
    zoomData: {},
    viewpoint: {},
    labelsVisible: [],
    screenHeight: {},
    mode: {},
    scale: {},
    color: [],
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
    fleetchartMode: (state) => {
      return (namespace: string) => state.mode[namespace] || "panzoom";
    },
    fleetchartScreenHeight: (state) => {
      return (namespace: string) => state.screenHeight[namespace] || "1x";
    },
    fleetchartScale: (state) => {
      return (namespace: string) => state.scale[namespace] || 1;
    },
    fleetchartViewpoint: (state) => {
      return (namespace: string) => state.viewpoint[namespace] || "side";
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
