import { defineStore } from "pinia";

type ListGeometryState = {
  // How tall one record of a list turned out to be, so the next load can
  // reserve the same. Keyed by list and viewport class: a cell that wraps on a
  // phone is not the cell the same list draws on a desktop.
  heights: {
    [key: string]: number;
  };
  // The most records a list has ever shown at once, capped by its page size
  // when it is read. A list that only ever holds two - a ship's videos - should
  // not reserve a full page of them, and nothing in the first answer says so.
  counts: {
    [key: string]: number;
  };
};

export const useListGeometryStore = defineStore("listGeometry", {
  state: (): ListGeometryState => ({
    heights: {},
    counts: {},
  }),
  getters: {
    findByKey: (store) => (key: string) => store.heights[key],
    countByKey: (store) => (key: string) => store.counts[key],
  },
  actions: {
    setByKey(key: string, height: number) {
      this.heights[key] = height;
    },
    // The high-water mark, not the last reading: the final page of a list holds
    // fewer records than the ones before it, and reserving from that would
    // leave every earlier page short.
    //
    // Zero is a reading like any other, and worth keeping: a ship with no
    // videos should reserve no room for them.
    recordCount(key: string, count: number) {
      const seen = this.counts[key];

      if (seen === undefined || count > seen) {
        this.counts[key] = count;
      }
    },
  },
  // Persisted, because the load that benefits most from knowing all this is the
  // first one after opening the page.
  persist: {
    pick: ["heights", "counts"],
  },
});
