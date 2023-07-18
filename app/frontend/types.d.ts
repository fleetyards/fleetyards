declare global {
  interface Window {
    APP_VERSION: string;
    STORE_VERSION: string;
    SC_DATA_VERSION: string;
    ON_SUBDOMAIN: boolean;
    APP_CODENAME: string;
    API_VERSION: string;
    API_OAS_VERSION: string;
    API_ENDPOINT: string;
    DATA_PREFETCH: KeyValuePair;
    FRONTEND_ENDPOINT: string;
    CABLE_ENDPOINT: string;
  }
}

export {};
