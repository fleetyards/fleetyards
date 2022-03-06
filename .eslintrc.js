module.exports = {
  env: {
    browser: true,
    es2021: true,
    node: true,
  },

  extends: [
    'eslint:recommended',
    'plugin:vue/recommended',
    'plugin:prettier/recommended',
  ],

  overrides: [
    {
      env: {
        'cypress/globals': true,
      },
      files: ['test/**/*.js'],
      plugins: ['cypress'],
      rules: {
        'global-require': 'off',
      },
    },
  ],

  parserOptions: {
    ecmaVersion: 'latest',
  },

  plugins: ['prettier', 'import'],

  root: true,

  rules: {
    'import/no-unresolved': [
      'error',
      {
        ignore: [
          '^@hotwired/turbo-rails$',
          '^@hotwired/stimulus$',
          '^@hotwired/stimulus-loading$',
        ],
      },
    ],
    'no-bitwise': 'off',
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
    'vue/component-name-in-template-casing': 'error',
    'vue/no-v-html': 'off',
    'vue/sort-keys': [
      'warn',
      'asc',
      {
        caseSensitive: false,
        natural: true,
      },
    ],
  },

  settings: {
    'import/resolver': {
      alias: {
        map: [
          ['@', './app/frontend'],
          ['admin-app', './app/javascript/admin-app'],
          ['frontend-app', './app/javascript/frontend-app'],
        ],
      },
    },
  },
}
