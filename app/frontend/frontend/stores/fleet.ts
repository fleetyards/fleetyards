import type { ShipListState } from "@/frontend/types";
import { defineStore } from "pinia";

interface FleetState extends ShipListState {
  grouped: boolean;
  preview: boolean;
  inviteToken?: string;
  money: boolean;
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
    pick: ["detailsVisible", "grouped", "money", "preview", "inviteToken"],
  },
});
