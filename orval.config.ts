import { defineConfig } from "orval";

export default defineConfig({
  fyApi: {
    output: {
      mode: "tags",
      workspace: "app/frontend/services/fyApi",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      mock: false,
      prettier: true,
      clean: true,
      override: {
        mutator: {
          path: "./axiosClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/v1/schema.yaml",
    },
  },
  fyAdminApi: {
    output: {
      mode: "tags",
      workspace: "app/frontend/services/fyAdminApi",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      mock: false,
      prettier: true,
      clean: true,
      override: {
        mutator: {
          path: "./axiosClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/admin/v1/schema.yaml",
    },
  },
});
