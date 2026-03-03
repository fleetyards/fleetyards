import { type ShipListState } from "@/frontend/types";
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
  tableViewCols: ModelTableViewColsEnum[];
  tableViewImageCols: ModelTableViewImageColsEnum[];
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
    detailsVisible: false,
    filterVisible: true,
    gridView: true,
    tableViewCols: [
      ModelTableViewColsEnum.LENGTH,
      ModelTableViewColsEnum.BEAM,
      ModelTableViewColsEnum.HEIGHT,
      ModelTableViewColsEnum.MASS,
      ModelTableViewColsEnum.CARGO,
      ModelTableViewColsEnum.MIN_CREW,
    ],
    tableViewImageCols: [ModelTableViewImageColsEnum.STORE_IMAGE],
  }),
  actions: {
    toggleHoloviewer() {
      this.holoviewerVisible = !this.holoviewerVisible;
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
      "detailsVisible",
      "gridView",
      "tableViewCols",
      "tableViewImageCols",
    ],
  },
});
