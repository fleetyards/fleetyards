module.exports = {
  root: true,

  env: {
    node: true,
    "cypress/globals": true,
  },

  extends: [
    "airbnb-base",
    "plugin:compat/recommended",
    "plugin:vue/recommended",
    "plugin:@typescript-eslint/recommended",
    "prettier",
    "@vue/typescript",
  ],

  parser: "vue-eslint-parser",

  parserOptions: {
    parser: "@typescript-eslint/parser",
  },

  plugins: [
    "@typescript-eslint",
    "cypress",
    "import",
    "prettier",
    "sort-class-members",
  ],

  settings: {
    "html/indent": "tab",
    polyfills: [
      "Promise",
      "Object.assign",
      "Object.entries",
      "Object.values",
      "Array.iterator",
    ],
    "import/resolver": {
      typescript: {},
      alias: {
        map: [
          ["@", "./app/frontend"],
          ["~", "."],
        ],
      },
    },
  },

  rules: {
    "@typescript-eslint/no-useless-constructor": "error",
    "@typescript-eslint/no-empty-function": "error",
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        argsIgnorePattern: "^_",
      },
    ],
    "class-methods-use-this": "off",
    "import/prefer-default-export": "off",
    "import/no-extraneous-dependencies": "off",
    "import/extensions": "off",
    "import/prefer-default-export": "off",
    "no-bitwise": "off",
    "no-console": [
      "error",
      {
        allow: ["info", "warn", "error"],
      },
    ],
    "no-empty-function": "off",
    "no-param-reassign": "off",
    "no-underscore-dangle": "off",
    "no-undef": "off",
    "no-unused-vars": [
      "error",
      {
        argsIgnorePattern: "^_",
      },
    ],
    "no-useless-constructor": "off",
    "no-useless-escape": "off",
    "no-use-before-define": "off",
    "sort-class-members/sort-class-members": [
      2,
      {
        order: [
          "[static-properties]",
          "[static-methods]",
          "[properties]",
          "constructor",
          "[getters]",
          "[everything-else]",
        ],
      },
    ],
    "space-before-function-paren": "off",
    "spaced-comment": [
      2,
      "always",
      {
        exceptions: ["-"],
        markers: ["/"],
      },
    ],
    "vue/component-name-in-template-casing": "error",
    "vue/no-v-html": "off",
  },
};
