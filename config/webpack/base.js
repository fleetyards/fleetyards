const { webpackConfig, merge } = require('@rails/webpacker')
const ForkTSCheckerWebpackPlugin = require('fork-ts-checker-webpack-plugin')
const vueConfig = require('./rules/vue')

webpackConfig.resolve.extensions.push('.vue')

module.exports = merge(vueConfig, webpackConfig, {
  plugins: [new ForkTSCheckerWebpackPlugin()],
})
