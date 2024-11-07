import { type ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum ModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturer_name",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
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
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
    detailsVisible: false,
    filterVisible: true,
    gridView: false,
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
  },
  persist: {
    paths: ["holoviewerVisible", "detailsVisible", "gridView", "tableViewCols"],
  },
});
