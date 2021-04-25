module.exports = {
  extends: ['stylelint-config-prettier', 'stylelint-config-standard'],
  plugins: ['stylelint-order', 'stylelint-config-rational-order/plugin'],
  rules: {
    'at-rule-no-unknown': null,
    'block-closing-brace-newline-before': 'always',
    'declaration-block-semicolon-newline-after': 'always',
    'number-leading-zero': 'never',
    'no-descending-specificity': null,
    'no-invalid-position-at-import-rule': null,
    'string-quotes': 'single',
    'order/properties-order': [],
    'plugin/rational-order': [
      true,
      {
        'border-in-box-model': false,
        'empty-line-between-groups': false,
      },
    ],
  },
}
