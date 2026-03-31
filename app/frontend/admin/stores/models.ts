import { type AdminShipListState } from "@/admin/types";
import { type Models } from "@/services/fyAdminApi";
import { defineStore } from "pinia";
import { type ListMeta } from "@/shared/components/BreadCrumbs/types";

export enum AdminModelTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  RSI_STORE_IMAGE = "rsiStoreImage",
  ANGLED_VIEW = "angledView",
}

export enum AdminModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturerName",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  QUANTUM_FUEL = "quantumFuelTankSize",
  HYDROGEN_FUEL = "hydrogenFuelTankSize",
  MIN_CREW = "minCrew",
  MAX_CREW = "maxCrew",
  SCM_SPEED = "scmSpeed",
  MAX_SPEED = "maxSpeed",
  GROUND_MAX_SPEED = "groundMaxSpeed",
  FOCUS = "focus",
  PRODUCTION_STATUS = "productionStatus",
  PRICE = "price",
  PLEDGE_PRICE = "pledgePrice",
  RSI_ID = "rsiId",
  HIDDEN = "hidden",
  ACTIVE = "active",
  CREATED_AT = "createdAt",
  UPDATED_AT = "updatedAt",
}

interface AdminModelsState extends AdminShipListState {
  tableViewCols: AdminModelTableViewColsEnum[];
  tableViewImageCols: AdminModelTableViewImageColsEnum[];
  list?: string[];
  listMeta?: ListMeta;
}

export const useModelsStore = defineStore("adminModels", {
  state: (): AdminModelsState => ({
    filterVisible: true,
    tableViewCols: [
      AdminModelTableViewColsEnum.RSI_ID,
      AdminModelTableViewColsEnum.CREATED_AT,
      AdminModelTableViewColsEnum.UPDATED_AT,
    ],
    tableViewImageCols: [
      AdminModelTableViewImageColsEnum.STORE_IMAGE,
      AdminModelTableViewImageColsEnum.RSI_STORE_IMAGE,
      AdminModelTableViewImageColsEnum.ANGLED_VIEW,
    ],
  }),
  actions: {
    toggleFilter() {
      this.filterVisible = !this.filterVisible;
    },
    setTableViewCols(cols: AdminModelTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
    setTableViewImageCols(cols: AdminModelTableViewImageColsEnum[]) {
      this.tableViewImageCols = cols;
    },
    setList(models?: Models) {
      this.list = models?.items.map((model) => model.id);
      this.listMeta = {
        totalCount: models?.meta.pagination?.totalCount || 0,
        perPage: models?.meta.pagination?.perPage || 0,
        currentPage: models?.meta.pagination?.currentPage || 0,
        totalPages: models?.meta.pagination?.totalPages || 0,
      };
    },
  },
  persist: {
    pick: ["tableViewCols", "tableViewImageCols"],
  },
});
