module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'header-max-length': [1, 'always', 100],
    'header-case': [0],
    'scope-case': [0],
    'type-enum': [2, 'always', ['release', 'chore', 'feat', 'fix', 'refactor']],
  },
}
