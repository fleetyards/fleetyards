module.exports = {
  root: true,

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

  plugins: ['prettier'],

  parserOptions: {
    ecmaVersion: 'latest',
  },

  rules: {
    'vue/component-name-in-template-casing': 'error',
    'vue/no-v-html': 'off',
    // 'class-methods-use-this': 'off',
    'no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
    'no-bitwise': 'off',
    'no-console': [
      'error',
      {
        allow: ['info', 'warn', 'error'],
      },
    ],
    // 'no-empty-function': 'off',
    // 'no-param-reassign': 'off',
    // 'no-underscore-dangle': 'off',
    // 'no-undef': 'off',
    // 'no-useless-constructor': 'off',
    // 'no-useless-escape': 'off',
    // 'no-use-before-define': 'off',
    // 'semi': ['error', 'never'],
  },

  settings: {
    'import/resolver': {
      alias: {
        map: [['@', 'app/frontend']],
      },
    },
  },

  overrides: [
    {
      files: ['test/**/*.js'],
      env: {
        'cypress/globals': true,
      },
      plugins: ['cypress'],
      rules: {
        'global-require': 'off',
      },
    },
  ],
}
