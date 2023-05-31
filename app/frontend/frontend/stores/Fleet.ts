import type { ShipListState } from "@/@types/stores/ShipList";
import { defineStore } from "pinia";

interface FleetState extends ShipListState {
  grouped: boolean;
  preview: boolean;
  inviteToken?: string;
  money: boolean;
}

export const useFleetStore = defineStore("Fleet", {
  state: (): FleetState => ({
    detailsVisible: false,
    filterVisible: true,
    fleetchartVisible: false,
    fleetchartZoomData: undefined,
    fleetchartViewpoint: "side",
    fleetchartLabels: false,
    fleetchartScreenHeight: "1x",
    fleetchartMode: "panzoom",
    fleetchartScale: 1,
    perPage: 30,
    money: true,
    grouped: true,
    preview: true,
    inviteToken: undefined,
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
    toggleFleetchart() {
      this.fleetchartVisible = !this.fleetchartVisible;
    },
    updatePerPage(payload: number) {
      this.perPage = payload;
    },
    toggleGrouped() {
      this.grouped = !this.grouped;
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
  },
  persist: {
    paths: [
      "detailsVisible",
      "fleetchartVisible",
      "fleetchartScale",
      "fleetchartZoomData",
      "fleetchartViewpoint",
      "fleetchartLabels",
      "fleetchartScreenHeight",
      "fleetchartMode",
      "fleetchartScale",
      "grouped",
      "money",
      "preview",
      "inviteToken",
      "perPage",
    ],
  },
});
