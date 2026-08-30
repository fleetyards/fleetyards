import "vue-router";
import type { FeatureFlagName } from "@/services/fyApi";

declare module "vue-router" {
  interface RouteMeta {
    title?: string;
    customTitle?: boolean;
    needsAuthentication?: boolean;
    primaryAction?: boolean;
    backgroundImage?: string;
    icon?: string;
    exact?: boolean;
    activeRoute?: string;
    /*
     * The tab this route belongs under, for a page that is reached from a tab
     * but is not one itself -- a record's detail. Without it the tab strip goes
     * blank as soon as you open one.
     */
    activeTab?: string;
    access?: string[];
    nav?: "main" | "sub" | "footer" | "editTabs" | "hidden";
    mobileNav?: number;
    href?: string;
    feature?: FeatureFlagName;
    // Read `feature` against the fleet in the route rather than the viewer.
    featureScope?: "fleet";
    hideWhenAuthenticated?: boolean;
    needsNoAuthentication?: boolean;
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
    OAUTH_ENDPOINT: string;
    CABLE_ENDPOINT: string;
    ON_SUBDOMAIN: boolean;
    NODE_ENV: string;
    GIT_REVISION: string;
    APPSIGNAL_KEY?: string;
    MAINTAINER_NAME: string;
    MAINTAINER_MAIL: string;
    MAINTAINER_ADDRESS_STREET: string;
    MAINTAINER_ADDRESS_POSTALCODE: string;
    MAINTAINER_ADDRESS_CITY: string;
    MAINTAINER_ADDRESS_COUNTRY: string;
    COPYRIGHT_OWNER: string;
    RSI_ENDPOINT: string;
    DIRECT_UPLOAD_URL: string;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    SwaggerUIBundle: any;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    SwaggerUIStandalonePreset: any;
  }
}
