const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')

environment.splitChunks(config => ({
  ...config,
  optimization: {
    splitChunks: { chunks: 'all', name: true },
    runtimeChunk: true,
  },
}))

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
module.exports = environment
