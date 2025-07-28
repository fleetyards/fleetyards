import { type ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum ModelTableViewImageColsEnum {
  STORE_IMAGE = "store_image",
  STORE_IMAGE_WIDE = "store_image_wide",
  ANGLED_VIEW = "angled_view",
  ANGLED_VIEW_WIDE = "angled_view_wide",
}

export enum ModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturer_name",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  QUANTUM_FUEL = "quantum_fuel_tank_size",
  HYDROGEN_FUEL = "hydrogen_fuel_tank_size",
  MIN_CREW = "min_crew",
  MAX_CREW = "max_crew",
  SCM_SPEED = "scm_speed",
  MAX_SPEED = "max_speed",
  GROUND_MAX_SPEED = "ground_max_speed",
  FOCUS = "focus",
  PRODUCTION_STATUS = "production_status",
  PRICE = "price",
  PLEDGE_PRICE = "pledge_price",
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
