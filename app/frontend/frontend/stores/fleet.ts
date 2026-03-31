import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

export enum FleetTableViewImageColsEnum {
  STORE_IMAGE = "storeImage",
  STORE_IMAGE_WIDE = "storeImageWide",
  ANGLED_VIEW = "angledView",
  ANGLED_VIEW_WIDE = "angledViewWide",
}

export enum FleetTableViewColsEnum {
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
  PRODUCTION_STATUS = "modelProductionStatus",
  PRICE = "modelPrice",
  PLEDGE_PRICE = "modelPledgePrice",
  OWNER = "owner",
}

interface FleetState extends ShipListState {
  grouped: boolean;
  preview: boolean;
  inviteToken?: string;
  money: boolean;
  tableViewImageCols: FleetTableViewImageColsEnum[];
  tableViewCols: FleetTableViewColsEnum[];
}

export const useFleetStore = defineStore("fleet", {
  state: (): FleetState => ({
    detailsVisible: false,
    filterVisible: true,
    money: true,
    grouped: true,
    preview: true,
    inviteToken: undefined,
    gridView: true,
    tableViewImageCols: [
      FleetTableViewImageColsEnum.STORE_IMAGE,
      FleetTableViewImageColsEnum.ANGLED_VIEW,
    ],
    tableViewCols: [
      FleetTableViewColsEnum.MANUFACTURER_NAME,
      FleetTableViewColsEnum.OWNER,
    ],
  }),
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
    toggleGrouped() {
      this.grouped = !this.grouped;
    },
    toggleGridView() {
      this.gridView = !this.gridView;
    },
    hidePreview() {
      this.preview = false;
    },
    saveInviteToken(payload: string) {
      this.inviteToken = payload;
    },
    resetInviteToken() {
      this.inviteToken = undefined;
    },
    setTableViewCols(cols: FleetTableViewColsEnum[]) {
      this.tableViewCols = cols;
    },
    setTableViewImageCols(cols: FleetTableViewImageColsEnum[]) {
      this.tableViewImageCols = cols;
    },
  },
  persist: {
    pick: [
      "detailsVisible",
      "grouped",
      "money",
      "preview",
      "inviteToken",
      "gridView",
      "tableViewImageCols",
      "tableViewCols",
    ],
  },
});
