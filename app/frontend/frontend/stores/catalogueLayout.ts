import { defineStore } from "pinia";

type CatalogueLayoutState = {
  // Cards with each item's picture, or dense rows. Rows stay the default: most
  // components carry no picture, and a row fits more figures per screen.
  componentsGridView: boolean;
  equipmentGridView: boolean;
  // The figures under each card's picture, as the ships list offers.
  componentsDetailsVisible: boolean;
  equipmentDetailsVisible: boolean;
};

export const useCatalogueLayoutStore = defineStore("catalogueLayout", {
  state: (): CatalogueLayoutState => ({
    componentsGridView: false,
    equipmentGridView: false,
    componentsDetailsVisible: false,
    equipmentDetailsVisible: false,
  }),
  persist: {
    pick: [
      "componentsGridView",
      "equipmentGridView",
      "componentsDetailsVisible",
      "equipmentDetailsVisible",
    ],
  },
});
