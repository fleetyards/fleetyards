import { type InjectionKey } from "vue";

// Where a section's cards remember being folded.
export interface MetricsCardFold {
  collapsed: (key: string) => boolean;
  toggle: (key: string) => void;
}

export const metricsCardFoldKey: InjectionKey<MetricsCardFold> =
  Symbol("metricsCardFold");

// A hardpoint card folds to its summary rows, not to its title.
export const hardpointCardFoldKey: InjectionKey<MetricsCardFold> =
  Symbol("hardpointCardFold");
