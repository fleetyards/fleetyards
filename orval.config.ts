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
      httpClient: "axios",
      mock: true,
      clean: true,
      prettier: true,
      override: {
        mutator: {
          path: "../axiosClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/v1/schema.yaml",
      override: {
        // axiosClient sends this on every request. As a declared parameter it
        // would put `params` ahead of `options` in every generated hook.
        transformer: "./orval.strip-sc-data-source.cjs",
      },
    },
  },
  fyOAuthApi: {
    output: {
      namingConvention: "PascalCase",
      mode: "tags-split",
      workspace: "app/frontend/services/fyOAuthApi",
      target: "./services",
      schemas: "./models",
      client: "vue-query",
      httpClient: "axios",
      mock: true,
      clean: true,
      prettier: true,
      override: {
        mutator: {
          path: "../axiosOAuthClient.ts",
          name: "axiosClient",
        },
      },
    },
    input: {
      target: "./swagger/oauth/v1/schema.yaml",
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
      httpClient: "axios",
      mock: true,
      clean: true,
      prettier: true,
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
