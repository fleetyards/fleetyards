import { type ShipListState } from "@/frontend/types";
// Type-only: a value import would put `@/services/fyApi` in the runtime graph of
// every store that reaches this one, and the specs that mock that module
// without `importOriginal` would lose whichever export they do not name.
import type { HangarSyncUnmatchedActionEnum } from "@/services/fyApi";
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

// Every sort the hangar can offer as a chip. Crew has a column but no sort: the
// server does not order by it.
export enum HangarSortFieldsEnum {
  RANK = "rank",
  NAME = "name",
  MANUFACTURER_NAME = "modelManufacturerName",
  LENGTH = "modelLength",
  BEAM = "modelBeam",
  HEIGHT = "modelHeight",
  MASS = "modelMass",
  CARGO = "modelCargo",
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
  syncModalOpen: boolean;
  syncRunning: boolean;
  syncAddBundledVehicles: boolean;
  syncUnmatchedVehiclesAction: HangarSyncUnmatchedActionEnum;
  syncUnmatchedHangarGroupId?: string;
  tableViewImageCols: HangarTableViewImageColsEnum[];
  tableViewCols: HangarTableViewColsEnum[];
  sortFields: HangarSortFieldsEnum[];
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
    syncModalOpen: false,
    syncRunning: false,
    syncAddBundledVehicles: true,
    syncUnmatchedVehiclesAction: "wishlist",
    syncUnmatchedHangarGroupId: undefined,
    tableViewImageCols: [
      HangarTableViewImageColsEnum.STORE_IMAGE,
      HangarTableViewImageColsEnum.ANGLED_VIEW,
    ],
    tableViewCols: [HangarTableViewColsEnum.MANUFACTURER_NAME],
    sortFields: [
      HangarSortFieldsEnum.RANK,
      HangarSortFieldsEnum.NAME,
      HangarSortFieldsEnum.MANUFACTURER_NAME,
      HangarSortFieldsEnum.LENGTH,
      HangarSortFieldsEnum.CARGO,
      HangarSortFieldsEnum.PRICE,
      HangarSortFieldsEnum.PRODUCTION_STATUS,
    ],
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
    setSortFields(fields: HangarSortFieldsEnum[]) {
      this.sortFields = fields;
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
      "sortFields",
      "syncAddBundledVehicles",
      "syncUnmatchedVehiclesAction",
      "syncUnmatchedHangarGroupId",
    ],
  },
});
