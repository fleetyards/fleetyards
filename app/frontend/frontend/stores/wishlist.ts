import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum WishlistTableViewImageColsEnum {
  STORE_IMAGE = "store_image",
  STORE_IMAGE_WIDE = "store_image_wide",
  ANGLED_VIEW = "angled_view",
  ANGLED_VIEW_WIDE = "angled_view_wide",
}

export enum WishlistTableViewColsEnum {
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
