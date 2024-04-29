declare global {
  interface Window {
    ADMIN_API_ENDPOINT: string;
    ON_SUBDOMAIN: boolean;
    NODE_ENV: string;
    GIT_REVISION: string;
    APP_VERSION: string;
    APP_CODENAME: string;
    STORE_VERSION: string;
    SENTRY_DSN?: string;
  }
}

export {};
