import { type ShipListState } from "@/frontend/types";
import { renameTableCols } from "@/frontend/utils/renamedTableCols";
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
  CREW = "modelCrew",
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
  // Per account, so a second person signing in on this browser still gets it.
  tourSeenBy: string[];
  money: boolean;
  extensionReady: boolean;
  extensionVersion?: string;
  // The sync modal shows the run, so the progress card stays out of its way.
  syncModalOpen: boolean;
  // The buy-back modal shows its run, so the progress card stays out of its
  // way.
  buybackSyncModalOpen: boolean;
  syncRunning: boolean;
  syncAddBundledVehicles: boolean;
  syncPaints: boolean;
  syncHangarFlair: boolean;
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
    tourSeenBy: [],
    gridView: true,
    extensionReady: false,
    extensionVersion: undefined,
    syncModalOpen: false,
    buybackSyncModalOpen: false,
    syncRunning: false,
    syncAddBundledVehicles: true,
    syncPaints: true,
    syncHangarFlair: true,
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
    hasSeenTour(state) {
      return (userId: string) => state.tourSeenBy.includes(userId);
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
    },
    add(payload: string) {
      this.ships.push(payload);
    },
    remove(payload: string) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
    markTourSeen(userId: string) {
      if (!this.hasSeenTour(userId)) this.tourSeenBy.push(userId);
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
      "tourSeenBy",
      "gridView",
      "tableViewImageCols",
      "tableViewCols",
      "sortFields",
      "syncAddBundledVehicles",
      "syncPaints",
      "syncHangarFlair",
      "syncUnmatchedVehiclesAction",
      "syncUnmatchedHangarGroupId",
    ],
    afterHydrate: ({ store }) => {
      store.tableViewCols = renameTableCols<HangarTableViewColsEnum>(
        store.tableViewCols,
        {
          modelMinCrew: HangarTableViewColsEnum.CREW,
          modelMaxCrew: HangarTableViewColsEnum.CREW,
        },
      );
    },
  },
});
