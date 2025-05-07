import { type ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum HangarTableViewColsEnum {
  MANUFACTURER_NAME = "model_manufacturer_name",
  LENGTH = "model_length",
  BEAM = "model_beam",
  HEIGHT = "model_height",
  MASS = "model_mass",
  CARGO = "model_cargo",
  MIN_CREW = "model_min_crew",
  MAX_CREW = "model_max_crew",
  SCM_SPEED = "model_scm_speed",
  MAX_SPEED = "model_max_speed",
  GROUND_MAX_SPEED = "model_ground_max_speed",
  FOCUS = "model_focus",
  PRODUCTION_STATUS = "model_production_status",
  PRICE = "model_price",
  PLEDGE_PRICE = "model_pledge_price",
}

interface HangarState extends ShipListState {
  ships: string[];
  preview: boolean;
  starterGuideVisible: boolean;
  money: boolean;
  extensionReady: boolean;
  tableViewCols: HangarTableViewColsEnum[];
}

export const useHangarStore = defineStore("hangar", {
  state: (): HangarState => ({
    detailsVisible: false,
    filterVisible: true,
    money: true,
    ships: [],
    preview: true,
    starterGuideVisible: false,
    gridView: true,
    extensionReady: false,
    tableViewCols: [HangarTableViewColsEnum.MANUFACTURER_NAME],
  }),
  getters: {
    empty(state) {
      return state.ships.length === 0;
    },
  },
  actions: {
    toggleDetails() {
      this.detailsVisible = !this.detailsVisible;
    },
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    toggleMoney() {
      this.money = !this.money;
    },
    hidePreview() {
      this.preview = false;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    save(payload: string[]) {
      this.ships = payload;

      if (payload.length > 0 && this.starterGuideVisible) {
        this.starterGuideVisible = false;
      }
    },
    add(payload: string) {
      this.ships.push(payload);

      if (this.starterGuideVisible) {
        this.starterGuideVisible = false;
      }
    },
    remove(payload: string) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
    enableStarterGuide() {
      this.starterGuideVisible = true;
    },
    setTableViewCols(cols: HangarTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
  },
  persist: {
    pick: [
      "ships",
      "detailsVisible",
      "preview",
      "money",
      "starterGuideVisible",
      "gridView",
      "tableViewCols",
    ],
  },
});
