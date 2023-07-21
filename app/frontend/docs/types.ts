declare global {
  interface Window {
    GIT_REVISION: string;
    APP_VERSION: string;
    APP_CODENAME: string;
    COPYRIGHT_OWNER: string;
    SC_DATA_VERSION: string;
  }
}

export {};
