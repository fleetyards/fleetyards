import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum WishlistTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  STORE_IMAGE_WIDE = "storeImageWide",
  ANGLED_VIEW = "angledView",
  ANGLED_VIEW_WIDE = "angledViewWide",
}

export enum WishlistTableViewColsEnum {
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

interface WishlistState extends ShipListState {
  ships: string[];
  tableViewImageCols: WishlistTableViewImageColsEnum[];
  tableViewCols: WishlistTableViewColsEnum[];
}

export const useWishlistStore = defineStore("wishlist", {
  state: (): WishlistState => ({
    detailsVisible: false,
    filterVisible: true,
    gridView: true,
    ships: [],
    tableViewImageCols: [WishlistTableViewImageColsEnum.STORE_IMAGE],
    tableViewCols: [WishlistTableViewColsEnum.MANUFACTURER_NAME],
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
    save(payload: string[]) {
      this.ships = payload;
    },
    add(payload: string) {
      this.ships.push(payload);
    },
    remove(payload: string) {
      this.ships.splice(this.ships.indexOf(payload), 1);
    },
    setTableViewCols(cols: WishlistTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
  },
  persist: {
    pick: [
      "ships",
      "detailsVisible",
      "gridView",
      "tableViewImageCols",
      "tableViewCols",
    ],
  },
});
