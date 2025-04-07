import { defineConfig } from "orval";

export default defineConfig({
  fyApi: {
    output: {
      namingConvention: "PascalCase",
      mode: "tags",
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
        query: {
          shouldExportQueryKey: false,
          queryOptions: {
            path: "./app/frontend/services/customQueryOptions.ts",
            name: "customQueryOptions",
          },
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
      mode: "tags",
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
        query: {
          shouldExportQueryKey: false,
          queryOptions: {
            path: "./app/frontend/services/customQueryOptions.ts",
            name: "customQueryOptions",
          },
        },
      },
    },
    input: {
      target: "./swagger/admin/v1/schema.yaml",
    },
  },
});
