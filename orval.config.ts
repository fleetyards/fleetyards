import { defineConfig } from "orval";

export default defineConfig({
  fyApi: {
    output: {
      namingConvention: "PascalCase",
      mode: "tags-split",
      workspace: "app/frontend/services/fyApi",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      mock: true,
      clean: true,
      override: {
        mutator: {
          path: "../axiosClient.ts",
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
      namingConvention: "PascalCase",
      mode: "tags-split",
      workspace: "app/frontend/services/fyAdminApi",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      mock: true,
      clean: true,
      override: {
        mutator: {
          path: "../axiosAdminClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/admin/v1/schema.yaml",
    },
  },
});
