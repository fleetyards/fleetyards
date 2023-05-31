import type { TFilters } from "@/@types/filters";
import { defineStore } from "pinia";

export type TFilteredPage =
  | "shop"
  | "shops"
  | "stations"
  | "stationImages"
  | "celestialObjects"
  | "starsystem"
  | "starsystems"
  | "tradeRoutes"
  | "images"
  | "models"
  | "modelImages"
  | "modelVideos"
  | "hangar"
  | "publicHangar"
  | "wishlist"
  | "publicWishlist"
  | "fleetShips"
  | "fleetPublicShips"
  | "fleetMembers"
  | "search"
  | "adminShopCommodities"
  | "adminCommodityPrices";

interface TFiltersState {
  filtersVisible: Record<TFilteredPage, boolean>;
  filters: Record<TFilteredPage, TFilters | undefined>;
}

export const useFiltersStore = defineStore("Filters", {
  state: (): TFiltersState => ({
    filtersVisible: {
      shop: false,
      shops: false,
      stations: false,
      stationImages: false,
      celestialObjects: false,
      starsystem: false,
      starsystems: false,
      tradeRoutes: false,
      images: false,
      models: false,
      modelImages: false,
      modelVideos: false,
      hangar: false,
      publicHangar: false,
      wishlist: false,
      publicWishlist: false,
      fleetShips: false,
      fleetPublicShips: false,
      fleetMembers: false,
      search: false,
      adminShopCommodities: false,
      adminCommodityPrices: false,
    },
    filters: {
      shop: undefined,
      shops: undefined,
      stations: undefined,
      stationImages: undefined,
      celestialObjects: undefined,
      starsystem: undefined,
      starsystems: undefined,
      tradeRoutes: undefined,
      images: undefined,
      models: undefined,
      modelImages: undefined,
      modelVideos: undefined,
      hangar: undefined,
      publicHangar: undefined,
      wishlist: undefined,
      publicWishlist: undefined,
      fleetShips: undefined,
      fleetPublicShips: undefined,
      fleetMembers: undefined,
      search: undefined,
      adminShopCommodities: undefined,
      adminCommodityPrices: undefined,
    },
  }),
  actions: {
    saveFilters(key: TFilteredPage, filters?: TFilters) {
      this.filters[key] = filters;
    },
    toggleFilter(key: TFilteredPage) {
      this.filtersVisible[key] = !this.filtersVisible[key];
    },
  },
  persist: {
    paths: ["filtersVisible"],
  },
});
