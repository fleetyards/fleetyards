import "vue-router";

declare module "vue-router" {
  interface RouteMeta {
    title?: string;
    needsAuthentication?: boolean;
    quickSearch?: string;
    primaryAction?: boolean;
    backgroundImage?: string;
    icon?: string;
    exact?: boolean;
    activeRoute?: string;
    access?: string;
    nav?: "main" | "footer" | "hidden";
    mobileNav?: number;
  }
}

declare global {
  interface Window {
    ADMIN_API_ENDPOINT: string;
    APP_VERSION: string;
    APP_NAME: string;
    STORE_VERSION: string;
    SC_DATA_VERSION: string;
    APP_CODENAME: string;
    API_VERSION: string;
    API_OAS_VERSION: string;
    API_ENDPOINT: string;
    DATA_PREFETCH: KeyValuePair;
    FLASH: KeyValuePair;
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
    RSI_ENDPOINT: string;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    SwaggerUIBundle: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    SwaggerUIStandalonePreset: any;
  }
}
