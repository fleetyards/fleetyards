module.exports = {
  extends: ['stylelint-config-prettier', 'stylelint-config-standard'],
  rules: {
    'at-rule-no-unknown': null,
    'block-closing-brace-newline-before': 'always',
    'declaration-block-semicolon-newline-after': 'always',
    'number-leading-zero': 'never',
    'no-descending-specificity': null,
    'string-quotes': 'single',
  },
}
