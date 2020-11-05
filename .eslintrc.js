module.exports = {
  root: true,

  env: {
    'node': true,
    'jest': true,
    'cypress/globals': true,
  },

  extends: [
    'airbnb-base',
    'plugin:compat/recommended',
    'plugin:jest/recommended',
    'plugin:vue/recommended',
    'plugin:vue-types/strongly-recommended',
    'prettier',
    'prettier/@typescript-eslint',
    'prettier/babel',
    'prettier/vue',
    '@vue/typescript',
  ],

  parserOptions: {
    parser: '@typescript-eslint/parser',
  },

  plugins: [
    '@typescript-eslint',
    'cypress',
    'import',
    'prettier',
    'sort-class-members',
  ],

  settings: {
    'html/indent': 'tab',
    'polyfills': [
      'Promise',
      'Object.assign',
      'Object.entries',
      'Object.values',
      'Array.iterator',
    ],
    'import/resolver': {
      webpack: {
        config: 'config/webpack/development.js',
      },
      alias: {
        map: [['helpers', './test/javascript/unit/helpers']],
      },
    },
  },

  rules: {
    '@typescript-eslint/no-useless-constructor': 'error',
    '@typescript-eslint/no-empty-function': 'error',
    '@typescript-eslint/no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
    'class-methods-use-this': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/extensions': 'off',
    'jest/expect-expect': 'off',
    'jest/no-mocks-import': 'off',
    'no-bitwise': 'off',
    'no-console': [
      'error',
      {
        allow: ['info', 'warn', 'error'],
      },
    ],
    'no-empty-function': 'off',
    'no-param-reassign': 'off',
    'no-underscore-dangle': 'off',
    'no-undef': 'off',
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
    'no-useless-constructor': 'off',
    'no-useless-escape': 'off',
    'no-use-before-define': 'off',
    'prettier/prettier': [
      'warn',
      {
        semi: false,
        quoteProps: 'consistent',
        trailingComma: 'all',
        singleQuote: true,
        htmlWhitespaceSensitivity: 'ignore',
      },
    ],
    'semi': ['error', 'never'],
    'sort-class-members/sort-class-members': [
      2,
      {
        order: [
          '[static-properties]',
          '[static-methods]',
          '[properties]',
          'constructor',
          '[getters]',
          '[everything-else]',
        ],
      },
    ],
    'space-before-function-paren': 'off',
    'spaced-comment': [
      2,
      'always',
      {
        exceptions: ['-'],
        markers: ['/'],
      },
    ],
    'vue/component-name-in-template-casing': 'error',
    'vue/no-v-html': 'off',
  },

  overrides: [
    {
      files: ['**/e2e/**/*.js'],
      rules: {
        'jest/valid-expect': 'off',
        'jest/no-standalone-expect': 'off',
        'jest/expect-expect': 'off',
      },
    },
  ],
}
