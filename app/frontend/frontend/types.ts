declare global {
  interface Window {
    APP_VERSION: string;
    STORE_VERSION: string;
    SC_DATA_VERSION: string;
    APP_CODENAME: string;
    API_VERSION: string;
    API_OAS_VERSION: string;
    API_ENDPOINT: string;
    DATA_PREFETCH: KeyValuePair;
    FRONTEND_ENDPOINT: string;
    CABLE_ENDPOINT: string;
    ON_SUBDOMAIN: boolean;
    NODE_ENV: string;
    GIT_REVISION: string;
    SENTRY_DSN?: string;
  }
}

export type ZoomData = {
  x: number;
  y: number;
  scale: number;
};

export interface ShipListState {
  detailsVisible: boolean;
  filterVisible: boolean;
  fleetchartVisible: boolean;
  fleetchartZoomData?: ZoomData;
  fleetchartViewpoint: "side" | "top" | "angled";
  fleetchartLabels: boolean;
  fleetchartScreenHeight: "1x" | "1_5x" | "2x" | "3x" | "4x";
  fleetchartMode: "panzoom" | "classic";
  fleetchartScale: number;
  perPage: number;
}
