import type { KnipConfig } from "knip";

const config: KnipConfig = {
  entry: ["app/frontend/entrypoints/*.ts"],
  project: ["app/frontend/**/*.{js,ts,vue}"],
};

export default config;
