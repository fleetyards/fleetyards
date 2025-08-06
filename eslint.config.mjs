import { globalIgnores } from "eslint/config";
import {
  defineConfigWithVueTs,
  vueTsConfigs,
} from "@vue/eslint-config-typescript";

export default defineConfigWithVueTs(
  [
    globalIgnores([
      "app/assets",
      "node_modules",
      "vendor",
      "public/vendor/js",
      "app/frontend/services",
      "**/postcss.config.js",
    ]),
    {
      rules: {
        "@typescript-eslint/no-unused-vars": [
          "error",
          {
            argsIgnorePattern: "^_",
            caughtErrorsIgnorePattern: "^_",
            varsIgnorePattern: "^_",
            destructuredArrayIgnorePattern: "^_",
          },
        ],
        "no-console": [
          "error",
          {
            allow: ["info", "warn", "error"],
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
  vueTsConfigs.recommendedTypeChecked,
);
