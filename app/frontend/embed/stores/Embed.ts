import type { FleetyardsEmbedConfig } from "@/entrypoints/embed_v2";
import { defineStore } from "pinia";

interface EmbedState {
  locale?: string;
  storeVersion?: string;
  details: boolean;
  fleetchart: boolean;
  fleetchartScale: number;
  grouping: boolean;
  fleetchartGrouping: boolean;
}

let config: FleetyardsEmbedConfig = {};
// @ts-expect-error defined on window
if (typeof fleetyards_config !== "undefined") {
  // @ts-expect-error defined on window
  config = fleetyards_config();
} else {
  config = window.FleetYardsFleetchartConfig || {};
}

const scale = Math.max(config.fleetchartScale || 0, 10);

export const useEmbedStore = defineStore("Embed", {
  state: (): EmbedState => ({
    locale: "en",
    storeVersion: undefined,
    details: config.details || true,
    fleetchart: config.fleetchart || false,
    fleetchartScale: scale,
    grouping: config.grouped || true,
    fleetchartGrouping: config.fleetchartGrouped || false,
  }),
  actions: {
    toggleDetails() {
      this.details = !this.details;
    },
    toggleFleetchart() {
      this.fleetchart = !this.fleetchart;
    },
    toggleGrouping() {
      this.grouping = !this.grouping;
    },
    toggleFleetchartGrouping() {
      this.fleetchartGrouping = !this.fleetchartGrouping;
    },
  },
  persist: {
    paths: [
      "storeVersion",
      "details",
      "fleetchart",
      "fleetchartScale",
      "grouping",
      "fleetchartGrouping",
    ],
  },
});
