import { type ShipListState } from "@/frontend/types";
import { ModelStateEnum } from "@/frontend/composables/useModelStates";
import { defineStore } from "pinia";

export enum ModelTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  STORE_IMAGE_WIDE = "storeImageWide",
  ANGLED_VIEW = "angledView",
  ANGLED_VIEW_WIDE = "angledViewWide",
}

export enum ModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturerName",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  QUANTUM_FUEL = "quantumFuelTankSize",
  HYDROGEN_FUEL = "hydrogenFuelTankSize",
  MIN_CREW = "minCrew",
  MAX_CREW = "maxCrew",
  SCM_SPEED = "scmSpeed",
  MAX_SPEED = "maxSpeed",
  GROUND_MAX_SPEED = "groundMaxSpeed",
  FOCUS = "focus",
  PRODUCTION_STATUS = "productionStatus",
  PRICE = "price",
  PLEDGE_PRICE = "pledgePrice",
}

interface ModelsState extends ShipListState {
  holoviewerVisible: boolean;
  modelState: ModelStateEnum;
  tableViewCols: ModelTableViewColsEnum[];
  tableViewImageCols: ModelTableViewImageColsEnum[];
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
    modelState: ModelStateEnum.RETRACTED,
    detailsVisible: false,
    filterVisible: true,
    gridView: true,
    tableViewImageCols: [
      ModelTableViewImageColsEnum.STORE_IMAGE,
      ModelTableViewImageColsEnum.ANGLED_VIEW,
    ],
    tableViewCols: [
      ModelTableViewColsEnum.LENGTH,
      ModelTableViewColsEnum.BEAM,
      ModelTableViewColsEnum.HEIGHT,
      ModelTableViewColsEnum.MASS,
      ModelTableViewColsEnum.CARGO,
      ModelTableViewColsEnum.MIN_CREW,
    ],
  }),
  actions: {
    toggleHoloviewer() {
      this.holoviewerVisible = !this.holoviewerVisible;
    },
    // One selection for the whole session: a visitor who wants ships landed
    // wants the next ship landed too, where it has the images for it.
    setModelState(state: ModelStateEnum) {
      this.modelState = state;
    },
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    setTableViewCols(cols: ModelTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
    setTableViewImageCols(cols: ModelTableViewImageColsEnum[]) {
      this.tableViewImageCols = cols;
    },
  },
  persist: {
    pick: [
      "holoviewerVisible",
      "modelState",
      "detailsVisible",
      "gridView",
      "tableViewCols",
      "tableViewImageCols",
    ],
  },
});
