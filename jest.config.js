module.exports = {
  testURL: 'http://localhost:3000',
  roots: [
    'app/javascript',
  ],
  moduleFileExtensions: [
    'js',
    'vue',
  ],
  setupFiles: [
    '<rootDir>/test/javascript/setup',
  ],
  snapshotSerializers: [
    '<rootDir>/node_modules/jest-serializer-vue',
  ],
  testPathIgnorePatterns: [
    'config',
  ],
  moduleNameMapper: {
    '\\.(css|less)$': '<rootDir>/__mocks__/styleMock.js',
    '\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$': '<rootDir>/__mocks__/fileMock.js',
  },
  moduleDirectories: [
    '<rootDir>/node_modules',
    '<rootDir>/app/javascript',
  ],
  transform: {
    '^.+\\.js$': '<rootDir>/node_modules/babel-jest',
    '.*\\.(vue)$': '<rootDir>/node_modules/vue-jest',
  },
}
