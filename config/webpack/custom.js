const ForkTSCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin')

module.exports = {
  resolve: {
    extensions: ['.vue'],
  },
  plugins: [new ForkTSCheckerWebpackPlugin()],
}
