const { defineConfig } = require('cypress')

module.exports = defineConfig({
  projectId: 'vngu15',
  fixturesFolder: 'test/javascript/e2e/fixtures',
  screenshotsFolder: 'test/javascript/e2e/screenshots',
  video: false,
  videosFolder: 'test/javascript/e2e/videos',
  videoUploadOnPasses: false,
  videoCompression: 0,
  viewportWidth: 2560,
  viewportHeight: 1440,
  defaultCommandTimeout: 10000,
  reporter: 'cypress-mochawesome-reporter',
  reporterOptions: {
    reportDir: 'test/reports/e2e',
  },
  e2e: {
    baseUrl: 'http://fleetyards.test',
    specPattern: 'test/javascript/e2e/specs/**/*.{js,jsx,ts,tsx}',
    supportFile: 'test/javascript/e2e/support/e2e.js',
  },
})
