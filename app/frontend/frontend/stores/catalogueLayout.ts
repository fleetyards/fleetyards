import { defineStore } from "pinia";

export type CatalogueList = "components" | "equipment";

export interface CatalogueListLayout {
  // Cards with each item's picture, or dense rows. Rows stay the default: most
  // components carry no picture, and a row fits more figures per screen.
  gridView: boolean;
  // The figures under each card's picture, as the ships list offers.
  detailsVisible: boolean;
}

export const useCatalogueLayoutStore = defineStore("catalogueLayout", {
  state: (): { lists: Record<CatalogueList, CatalogueListLayout> } => ({
    lists: {
      components: { gridView: false, detailsVisible: false },
      equipment: { gridView: false, detailsVisible: false },
    },
  }),
  persist: {
    pick: ["lists"],
  },
});
