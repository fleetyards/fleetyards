import { defineStore } from "pinia";
import type { FleetYardsFleetchartConfig } from "@/embed/types";

type EmbedState = {
  storeVersion?: string;
  details: boolean;
  fleetchart: boolean;
  fleetchartScale: number;
  grouping: boolean;
  fleetchartGrouping: boolean;
};

let config: FleetYardsFleetchartConfig = {};
if (window.fleetyards_config) {
  config = window.fleetyards_config();
} else {
  config = window.FleetYardsFleetchartConfig || {};
}

const scale = Math.max(Number(config.fleetchartScale) || 0, 10);

export const useEmbedStore = defineStore("embed", {
  state: (): EmbedState => ({
    storeVersion: window.STORE_VERSION,
    details: config.details || true,
    fleetchart: config.fleetchart || false,
    fleetchartScale: scale,
    grouping: config.grouped || true,
    fleetchartGrouping: config.fleetchartGrouped || false,
  }),
  persist: true,
});
