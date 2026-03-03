import { type ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum HangarTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  STORE_IMAGE_WIDE = "storeImageWide",
  ANGLED_VIEW = "angledView",
  ANGLED_VIEW_WIDE = "angledViewWide",
}

export enum HangarTableViewColsEnum {
  MANUFACTURER_NAME = "modelManufacturerName",
  LENGTH = "modelLength",
  BEAM = "modelBeam",
  HEIGHT = "modelHeight",
  MASS = "modelMass",
  CARGO = "modelCargo",
  MIN_CREW = "modelMinCrew",
  MAX_CREW = "modelMaxCrew",
  SCM_SPEED = "modelScmSpeed",
  MAX_SPEED = "modelMaxSpeed",
  GROUND_MAX_SPEED = "modelGroundMaxSpeed",
  FOCUS = "modelFocus",
  PRODUCTION_STATUS = "modelProductionStatus",
  PRICE = "modelPrice",
  PLEDGE_PRICE = "modelPledgePrice",
}

interface HangarState extends ShipListState {
  ships: string[];
  preview: boolean;
  starterGuideVisible: boolean;
  money: boolean;
  extensionReady: boolean;
  tableViewImageCols: HangarTableViewImageColsEnum[];
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
    tableViewImageCols: [HangarTableViewImageColsEnum.STORE_IMAGE],
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
    setTableViewImageCols(cols: HangarTableViewImageColsEnum[]) {
      this.tableViewImageCols = cols;
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
      "tableViewImageCols",
      "tableViewCols",
    ],
  },
});
