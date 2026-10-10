import type { ShipListState } from "@/frontend/types";
import { renameTableCols } from "@/frontend/utils/renamedTableCols";
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
  CREW = "modelCrew",
  SCM_SPEED = "modelScmSpeed",
  MAX_SPEED = "modelMaxSpeed",
  GROUND_MAX_SPEED = "modelGroundMaxSpeed",
  PRODUCTION_STATUS = "modelProductionStatus",
  PRICE = "modelPrice",
  PLEDGE_PRICE = "modelPledgePrice",
  OWNER = "owner",
}

// Every sort the fleet's ship list can offer as a chip. A grouped list holds
// ships rather than vehicles, so each of these names the ship -- or, for the
// count, how many of it the fleet holds.
export enum FleetSortFieldsEnum {
  NAME = "modelName",
  COUNT = "vehiclesCount",
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

interface FleetState extends ShipListState {
  grouped: boolean;
  preview: boolean;
  inviteToken?: string;
  money: boolean;
  tableViewImageCols: FleetTableViewImageColsEnum[];
  tableViewCols: FleetTableViewColsEnum[];
  sortFields: FleetSortFieldsEnum[];
  dismissedFidWarnings: string[];
  // When each `${userId}:${fleetId}` setup tour was queued: set when the
  // account creates the fleet, cleared once the tour has been shown.
  pendingTours: Record<string, number>;
  // The fleet whose setup tour is running, or last ran. The tour is mounted by
  // the app rather than a fleet page, because every navigation remounts the
  // page -- and the tour walks across them.
  tourFleet?: { id: string; slug: string };
  tourOpen: boolean;
}

const tourKey = (userId: string, fleetId: string) => `${userId}:${fleetId}`;

// Past this, "your fleet is ready" no longer greets a fleet just made. An entry
// for a fleet that was deleted or never opened again is dropped the next time
// a tour is queued or cleared.
const PENDING_TOUR_TTL = 7 * 24 * 60 * 60 * 1000;

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
    sortFields: [
      FleetSortFieldsEnum.NAME,
      FleetSortFieldsEnum.COUNT,
      FleetSortFieldsEnum.MANUFACTURER_NAME,
      FleetSortFieldsEnum.LENGTH,
      FleetSortFieldsEnum.CARGO,
      FleetSortFieldsEnum.PRICE,
      FleetSortFieldsEnum.PRODUCTION_STATUS,
    ],
    dismissedFidWarnings: [],
    pendingTours: {},
    tourFleet: undefined,
    tourOpen: false,
  }),
  getters: {
    isTourPending(state) {
      return (userId: string, fleetId: string) =>
        Date.now() - (state.pendingTours[tourKey(userId, fleetId)] ?? 0) <
        PENDING_TOUR_TTL;
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
    setSortFields(fields: FleetSortFieldsEnum[]) {
      this.sortFields = fields;
    },
    dismissFidWarning(key: string) {
      if (!this.dismissedFidWarnings.includes(key)) {
        this.dismissedFidWarnings.push(key);
      }
    },
    queueTour(userId: string, fleetId: string) {
      this.pruneTours();
      this.pendingTours[tourKey(userId, fleetId)] = Date.now();
    },
    openTour(fleet: { id: string; slug: string }) {
      this.tourFleet = { id: fleet.id, slug: fleet.slug };
      this.tourOpen = true;
    },
    closeTour() {
      this.tourOpen = false;
    },
    clearTour(userId: string, fleetId: string) {
      delete this.pendingTours[tourKey(userId, fleetId)];
      this.pruneTours();
    },
    pruneTours() {
      const now = Date.now();

      Object.entries(this.pendingTours).forEach(([key, queuedAt]) => {
        if (now - queuedAt >= PENDING_TOUR_TTL) delete this.pendingTours[key];
      });
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
      "sortFields",
      "dismissedFidWarnings",
      "pendingTours",
    ],
    afterHydrate: ({ store }) => {
      store.tableViewCols = renameTableCols<FleetTableViewColsEnum>(
        store.tableViewCols,
        {
          modelMinCrew: FleetTableViewColsEnum.CREW,
          modelMaxCrew: FleetTableViewColsEnum.CREW,
        },
      );
    },
  },
});
