declare global {
  interface Window {
    APP_VERSION: string;
    APP_NAME: string;
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
    MAINTAINER_NAME: string;
    MAINTAINER_MAIL: string;
    MAINTAINER_ADDRESS_STREET: string;
    MAINTAINER_ADDRESS_POSTALCODE: string;
    MAINTAINER_ADDRESS_CITY: string;
    MAINTAINER_ADDRESS_COUNTRY: string;
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
}
