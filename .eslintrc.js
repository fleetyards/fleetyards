module.exports = {
  root: true,

  parserOptions: {
    parser: 'babel-eslint'
  },

  extends: [
    'airbnb-base',
    'plugin:vue/recommended',
    'plugin:jest/recommended',
    "plugin:compat/recommended",
    '@vue/typescript',
  ],

  plugins: [
    'cypress',
    'jest',
    'import',
  ],

  settings: {
    'html/indent': 'tab',
    polyfills: ['Promise', 'Object.assign'],
  },

  rules: {
    'no-bitwise': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/extensions': 'off',
    'import/no-unresolved': 'off',
    'no-underscore-dangle': 'off',
    semi: ['error', 'never'],
    'no-console': [
      'error', { allow: ['info', 'warn', 'error'] }
    ],
    'no-unused-vars': ['error', {
      'argsIgnorePattern': '^_'
    }],
    'no-useless-escape': 0,
    'space-before-function-paren': 0,
    'vue/no-v-html': 'off',
    'vue/component-name-in-template-casing': 'error',
    'spaced-comment': [2, 'always', {exceptions: ['-'], markers: ['/']}],
    'jest/no-mocks-import': 'off',
  },

  env: {
    browser: true,
    node: true,
    jest: true,
    mocha: true,
    'cypress/globals': true,
  },

  overrides: [{
    files: ['**/e2e/**/*.js'],
    rules: {
      'jest/valid-expect': 'off',
      'jest/no-standalone-expect': 'off',
      'jest/expect-expect': 'off',
    }
  }, {
    files: ['**/Impressum/index.vue', '**/Panel/index.vue', '**/*.ts'],
    parserOptions: {
      parser: '@typescript-eslint/parser',
    },
  }],
}
