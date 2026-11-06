import { type InjectionKey } from "vue";

// A page whose metrics cards fold, and which remembers the folded ones.
export interface MetricsCardFold {
  collapsed: (key: string) => boolean;
  toggle: (key: string) => void;
}

export const metricsCardFoldKey: InjectionKey<MetricsCardFold> =
  Symbol("metricsCardFold");
