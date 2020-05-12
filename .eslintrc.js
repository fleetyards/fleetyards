module.exports = {
  root: true,

  env: {
    node: true,
    jest: true,
    'cypress/globals': true,
  },

  extends: [
    'plugin:vue/recommended',
    'plugin:vue-types/strongly-recommended',
    'plugin:jest/recommended',
    'airbnb-base',
    "plugin:compat/recommended",
    'prettier',
    'prettier/@typescript-eslint',
    'prettier/babel',
    'prettier/vue',
    '@vue/typescript',
  ],

  parserOptions: {
    parser: 'babel-eslint',
  },

  plugins: [
    'import',
    'prettier',
    'cypress',
  ],

  settings: {
    'html/indent': 'tab',
    polyfills: [
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
    'prettier/prettier': ['warn', {
      semi: false,
      quoteProps: 'consistent',
      trailingComma: 'all',
      singleQuote: true,
      htmlWhitespaceSensitivity: 'ignore',
    }],
    'no-bitwise': 'off',
    'import/no-extraneous-dependencies': 'off',
    'import/extensions': 'off',
    'import/no-unresolved': 'off',
    'no-underscore-dangle': 'off',
    semi: ['error', 'never'],
    'no-console': [
      'error', {
        allow: ['info', 'warn', 'error']
      }
    ],
    'no-unused-vars': ['error', {
      'argsIgnorePattern': '^_'
    }],
    'no-useless-escape': 0,
    'space-before-function-paren': 0,
    'vue/no-v-html': 'off',
    'vue/component-name-in-template-casing': 'error',
    'spaced-comment': [2, 'always', {
      exceptions: ['-'],
      markers: ['/']
    }],
    'jest/no-mocks-import': 'off',
  },

  overrides: [{
    files: ['**/e2e/**/*.js'],
    rules: {
      'jest/valid-expect': 'off',
      'jest/no-standalone-expect': 'off',
      'jest/expect-expect': 'off',
    }
  }, {
    files: [
      '**/*.ts',
      '**/components/**/*.vue',
      '**/Impressum/index.vue',
      '**/partials/Fleetchart/**',
    ],
    parserOptions: {
      parser: '@typescript-eslint/parser',
    },
    rules: {
      'class-methods-use-this': 'off',
      'no-unused-vars': 'off',
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
        },
      ],
    }
  }],
}
