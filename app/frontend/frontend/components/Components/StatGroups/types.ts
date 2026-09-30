import type { HardpointStat } from "@/frontend/composables/useHardpointStats";

export interface StatGroup {
  key: string;
  title: string;
  stats: HardpointStat[];
}
