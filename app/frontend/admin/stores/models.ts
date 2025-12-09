import { type AdminShipListState } from "@/admin/types";
import { type Models } from "@/services/fyAdminApi";
import { defineStore } from "pinia";
import { type ListMeta } from "@/shared/components/BreadCrumbs/index.vue";

export enum AdminModelTableViewImageColsEnum {
  STORE_IMAGE = "store_image",
  RSI_STORE_IMAGE = "rsi_store_image",
  ANGLED_VIEW = "angled_view",
}

export enum AdminModelTableViewColsEnum {
  MANUFACTURER_NAME = "manufacturer_name",
  LENGTH = "length",
  BEAM = "beam",
  HEIGHT = "height",
  MASS = "mass",
  CARGO = "cargo",
  QUANTUM_FUEL = "quantum_fuel_tank_size",
  HYDROGEN_FUEL = "hydrogen_fuel_tank_size",
  MIN_CREW = "min_crew",
  MAX_CREW = "max_crew",
  SCM_SPEED = "scm_speed",
  MAX_SPEED = "max_speed",
  GROUND_MAX_SPEED = "ground_max_speed",
  FOCUS = "focus",
  PRODUCTION_STATUS = "production_status",
  PRICE = "price",
  PLEDGE_PRICE = "pledge_price",
  RSI_ID = "rsi_id",
  HIDDEN = "hidden",
  ACTIVE = "active",
  CREATED_AT = "created_at",
  UPDATED_AT = "updated_at",
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
