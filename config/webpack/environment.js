const { environment } = require('@rails/webpacker')
const WorkboxPlugin = require('workbox-webpack-plugin')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)

environment.splitChunks(config => ({
  ...config,
  optimization: {
    splitChunks: { chunks: 'all', name: true },
    runtimeChunk: true,
  },
}))

environment.plugins.prepend('Provide', new WorkboxPlugin.GenerateSW())

module.exports = environment
