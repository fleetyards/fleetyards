import { defineStore } from "pinia";

type EventsStoreState = {
  // The list view's two shapes: cards with their covers, or dense rows.
  // Persisted per viewer, the way the contracts board keeps its own. Only the
  // list is affected - the calendar is a third shape, and it rides in the
  // route rather than here because a month can be linked to.
  gridView: boolean;
};

export const useEventsStore = defineStore("events", {
  state: (): EventsStoreState => ({
    gridView: true,
  }),
  actions: {
    toggleGridView() {
      this.gridView = !this.gridView;
    },
  },
  persist: {
    pick: ["gridView"],
  },
});
