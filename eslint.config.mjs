import { globalIgnores } from "eslint/config";
import {
  defineConfigWithVueTs,
  vueTsConfigs,
} from "@vue/eslint-config-typescript";
import tanstackQuery from "@tanstack/eslint-plugin-query";
import prettierConfig from "eslint-config-prettier";
import compatPlugin from "eslint-plugin-compat";
import importPlugin from "eslint-plugin-import";
import vuejsAccessibility from "eslint-plugin-vuejs-accessibility";
import globals from "globals";
import { readFileSync } from "fs";
import { dirname, join } from "path";
import { fileURLToPath } from "url";

// Get current directory for file resolution
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Load auto-import globals from unplugin-auto-import
const autoImportGlobals = JSON.parse(
  readFileSync(join(__dirname, ".eslintrc-auto-import.json"), "utf8"),
);

// Custom globals needed beyond standard browser/node globals
const customGlobals = {
  NodeListOf: "readonly",
};

// Import resolver alias configuration (mirrors vite.config.ts resolve.alias)
const importResolverSettings = {
  "import/resolver": {
    alias: {
      map: [["@", "./app/frontend"]],
      extensions: [".js", ".ts", ".vue", ".json"],
    },
  },
};

// Plugins shared across JS/TS/Vue file configurations
const sharedPlugins = {
  "@tanstack/query": tanstackQuery,
  compat: compatPlugin,
  "vuejs-accessibility": vuejsAccessibility,
  import: importPlugin,
};

// Rules shared across all file types
const sharedRules = {
  "no-console": [
    "error",
    {
      allow: ["info", "warn", "error"],
    },
  ],

  // Accessibility rules
  "vuejs-accessibility/label-has-for": [
    "error",
    {
      required: {
        some: ["nesting", "id"],
      },
    },
  ],
  "vuejs-accessibility/no-autofocus": "off",
  "vuejs-accessibility/media-has-caption": "warn",
  "vuejs-accessibility/heading-has-content": [
    "error",
    {
      accessibleDirectives: ["safe-html"],
    },
  ],
  "vuejs-accessibility/anchor-has-content": [
    "error",
    {
      accessibleDirectives: ["safe-html"],
    },
  ],

  // Import rules
  "import/no-unresolved": [
    "error",
    {
      caseSensitive: true,
      ignore: [
        "^vue$",
        "^vue-router(/.*)?$",
        "^@tanstack/vue-query$",
        "^@vueuse/core$",
        "^vitest$",
        "^node:",
        "\\?url$",
        "\\?raw$",
        "\\?inline$",
        "^@/services/", // Auto-generated API client files
        "^@tresjs/", // ESM-only package, resolver can't handle exports map
      ],
    },
  ],
  "import/no-self-import": "error",

  // TanStack Query rules
  "@tanstack/query/exhaustive-deps": "error",
  "@tanstack/query/stable-query-client": "error",

  // Browser compatibility rules
  "compat/compat": "error",
};

export default defineConfigWithVueTs(
  [
    globalIgnores([
      "app/assets",
      "data",
      "node_modules",
      "vendor",
      "public/vendor/js",
      "app/frontend/services",
      "**/postcss.config.js",
    ]),
  ],

  vueTsConfigs.recommendedTypeChecked,

  // Prettier config to disable conflicting formatting rules
  prettierConfig,

  // Configuration for JS and Vue files
  {
    files: ["**/*.{js,vue}"],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...autoImportGlobals.globals,
        ...customGlobals,
      },
      ecmaVersion: 2022,
      sourceType: "module",
    },
    plugins: sharedPlugins,
    settings: importResolverSettings,
    rules: {
      ...sharedRules,
      "vue/multi-word-component-names": "off",
      "vue/no-setup-props-destructure": "off",
      "vue/require-default-prop": "off",
    },
  },

  // Configuration for TypeScript files
  {
    files: ["**/*.{ts,tsx,mts,cts}"],
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...autoImportGlobals.globals,
        ...customGlobals,
      },
    },
    plugins: sharedPlugins,
    settings: importResolverSettings,
    rules: {
      ...sharedRules,
      "no-unused-vars": "off",
    },
  },

  // TypeScript rule overrides
  [
    {
      rules: {
        // Rules matching platform settings
        "@typescript-eslint/no-floating-promises": [
          "error",
          {
            ignoreVoid: true,
            ignoreIIFE: true,
          },
        ],
        "@typescript-eslint/await-thenable": "error",
        "@typescript-eslint/no-misused-promises": [
          "error",
          {
            checksVoidReturn: {
              attributes: false,
            },
          },
        ],

        // Rules not enabled in platform, kept off
        "@typescript-eslint/no-redundant-type-constituents": "off",
        "@typescript-eslint/require-await": "off",
        "@typescript-eslint/no-unsafe-enum-comparison": "off",
        "@typescript-eslint/no-empty-object-type": "off",
        "@typescript-eslint/prefer-promise-reject-errors": "off",
        "@typescript-eslint/no-unnecessary-type-assertion": "off",

        "@typescript-eslint/no-unused-vars": [
          "error",
          {
            argsIgnorePattern: "^_",
            caughtErrorsIgnorePattern: "^_",
            varsIgnorePattern: "^_",
            destructuredArrayIgnorePattern: "^_",
          },
        ],

        "@typescript-eslint/ban-ts-comment": [
          "error",
          {
            "ts-ignore": "allow-with-description",
          },
        ],
      },
    },
  ],
);
