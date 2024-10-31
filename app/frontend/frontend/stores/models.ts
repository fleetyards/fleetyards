import { type ShipListState, TableViewColsEnum } from "@/frontend/types";
import { defineStore } from "pinia";

interface ModelsState extends ShipListState {
  holoviewerVisible: boolean;
}

export const useModelsStore = defineStore("models", {
  state: (): ModelsState => ({
    holoviewerVisible: false,
    detailsVisible: false,
    filterVisible: true,
    gridView: false,
    tableViewCols: [
      TableViewColsEnum.LENGTH,
      TableViewColsEnum.BEAM,
      TableViewColsEnum.HEIGHT,
      TableViewColsEnum.MASS,
      TableViewColsEnum.CARGO,
      TableViewColsEnum.CREW,
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
    setTableViewCols(cols: TableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
  },
  persist: {
    paths: ["holoviewerVisible", "detailsVisible", "gridView", "tableViewCols"],
  },
});
