module.exports = {
  testURL: 'http://localhost:3000',
  roots: ['app/packs'],
  collectCoverage: false,
  collectCoverageFrom: [
    'app/packs/**/*.{js,vue,ts}',
    'app/packs/translations/**',
  ],
  preset: 'ts-jest',
  globals: {
    'ts-jest': {
      babelConfig: true,
    },
  },
  coverageDirectory: '<rootDir>/test/javascript/unit/coverage',
  coverageReporters: ['json', 'lcov', 'text'],
  moduleFileExtensions: ['js', 'vue', 'ts'],
  setupFiles: ['<rootDir>/test/javascript/unit/setup'],
  snapshotSerializers: ['jest-serializer-vue'],
  testPathIgnorePatterns: ['config'],
  moduleNameMapper: {
    '\\.(css|sass|scss)$': '<rootDir>/test/javascript/unit/__mocks__/style.js',
  },
  transform: {
    '^.+\\.js$': 'babel-jest',
    '.*\\.(vue)$': 'vue-jest',
    '^.+\\.tsx?$': 'ts-jest',
    '.+\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$':
      'jest-transform-stub',
  },
  moduleDirectories: [
    '<rootDir>/node_modules',
    '<rootDir>/app/packs',
    '<rootDir>/test/javascript/unit',
  ],
}
