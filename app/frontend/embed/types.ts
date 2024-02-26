import type { App } from "vue";

// deprecated
export type LegacyFleetyardsConfigFunction = () => FleetYardsFleetchartConfig;

export type FleetYardsFleetchart = App<Element>;

export type FleetYardsFleetchartConfig = {
  details?: boolean;
  grouped?: boolean;
  fleetchart?: boolean;
  fleetchartGrouped?: boolean;
  fleetchartSlider?: boolean;
  fleetchartScale?: number;
  groupedButton?: boolean;
  ships?: string[];
  fleetId?: string;
  // deprecated
  fleetID?: string;
  users?: string[];
};

declare global {
  interface Window {
    STORE_VERSION: string;
    API_ENDPOINT: string;
    FRONTEND_ENDPOINT: string;
    FleetYardsFleetchart?: FleetYardsFleetchart;
    FleetYardsFleetchartConfig?: FleetYardsFleetchartConfig;
    // deprecated
    fleetyards_config?: LegacyFleetyardsConfigFunction;
  }
}

export {};
