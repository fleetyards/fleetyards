module.exports = {
  root: true,

  env: {
    'node': true,
    'jest': true,
    'cypress/globals': true,
  },

  extends: [
    'plugin:vue/recommended',
    'plugin:vue-types/strongly-recommended',
    'plugin:jest/recommended',
    'airbnb-base',
    'plugin:compat/recommended',
    'prettier',
    'prettier/@typescript-eslint',
    'prettier/babel',
    'prettier/vue',
    '@vue/typescript',
  ],

  parserOptions: {
    parser: 'babel-eslint',
  },

  plugins: ['sort-class-members', 'import', 'prettier', 'cypress'],

  settings: {
    'html/indent': 'tab',
    'polyfills': [
      'Promise',
      'Object.assign',
      'Object.entries',
      'Object.values',
      'Array.iterator',
    ],
    // 'import/resolver': {
    //   typescript: {},
    // },
  },

  rules: {
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
    'no-bitwise': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/extensions': 'off',
    'import/no-unresolved': 'off',
    'no-underscore-dangle': 'off',
    'semi': ['error', 'never'],
    'no-console': [
      'error',
      {
        allow: ['info', 'warn', 'error'],
      },
    ],
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
    'no-useless-escape': 0,
    'space-before-function-paren': 0,
    'vue/no-v-html': 'off',
    'vue/component-name-in-template-casing': 'error',
    'spaced-comment': [
      2,
      'always',
      {
        exceptions: ['-'],
        markers: ['/'],
      },
    ],
    'jest/no-mocks-import': 'off',
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
    {
      files: ['**/*.ts', '**/*.vue'],
      parserOptions: {
        parser: '@typescript-eslint/parser',
      },
      rules: {
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
        'class-methods-use-this': 'off',
        'no-unused-vars': 'off',
        'no-useless-constructor': 'off',
        '@typescript-eslint/no-useless-constructor': 'error',
        'no-empty-function': 'off',
        '@typescript-eslint/no-empty-function': 'error',
        '@typescript-eslint/no-unused-vars': [
          'error',
          {
            argsIgnorePattern: '^_',
          },
        ],
      },
    },
  ],
}
